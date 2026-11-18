# Fragments shared by the model files in models/. It takes `pkgs`, and only
# because the pinned chat template below is a fixed-output derivation:
# models/default.nix imports it once and passes it to every file as `modelLib`. A
# model file never imports it itself.
#
# The convention is owned by skills/model-files/references/module-shape.md.
{pkgs}: let
  # Request-level DRY parameters. The same four numbers reach llama.cpp as
  # `--dry-*` server flags through `dryArgs`, or per request through a filter.
  # The binding carries the `Params` suffix because `profiles` and `dryVariants`
  # expose a key called `dry`: naming both `dry` would put an `x = x;` shape in
  # the file, and that shape becomes infinite recursion the moment a `rec` is
  # written on the enclosing set. The rename is the guard, not a style choice.
  dryParams = {
    dry_multiplier = 0.4;
    dry_base = 1.75;
    dry_allowed_length = 3;
    dry_penalty_last_n = 2048;
  };

  # Client-id suffix and reasoning budget of each `dry-budget-*` role. The label
  # is not derived from the budget: the two shipped ids say 4000 while the budget
  # is 4096, and renaming an id breaks the client that already uses it.
  defaultBudgets = [
    {
      label = "4000";
      budget = 4096;
    }
    {
      label = "6144";
      budget = 6144;
    }
  ];

  budgetRoles = {label, budget}: {
    "dry-budget-${label}" = dryParams // {reasoning_budget = budget;};
    "dry-budget-${label}-msg" = dryParams // {
      reasoning_budget = budget;
      reasoning_budget_message = "Enough think. Act now. Finish task. No loops.";
    };
    "dry-budget-${label}-empty-msg" = dryParams // {
      reasoning_budget = budget;
      reasoning_budget_message = "...";
    };
  };

  # What the five role profiles hold equal, so no role can invalidate the spec preset
  # its `cmd` drafts with. `top_p` is 0.95 from `thinking`/`coding` instead of 0.8 from
  # `instruct`/`agent`: the reference's measured default id is `thinking`, so the roles
  # keep the geometry their control was taken on. `repeat_penalty` is 1.0, the value of
  # three of the four base profiles. `presence_penalty` and DRY are 0 as a correction
  # of this GGUF, not as a role value: the copy round of 2026-11-16 (`presence_penalty 0
  # with DRY on` 0/10, `dry_multiplier 0` 10/10) took both to 0, and the bare id serves
  # them at 0 too. XTC stays out: it is a roleplay sampler.
  roleBase = {
    top_p = 0.95;
    top_k = 20;
    min_p = 0.0;
    presence_penalty = 0.0;
    repeat_penalty = 1.0;
    dry_multiplier = 0.0;
  };

  # Reasoning off through the chat template, not through a sampling value. The server
  # defaults carry the sampling; this only closes the thinking block. It reaches the
  # `instruct` role as an argument of `mkRoles` below, not by sitting in whatever set
  # surrounds it. `profiles.noThink` stays as an alias for the three model files that
  # read it; the binding carries the `Params` suffix so neither alias reads as `x = x;`.
  noThinkParams = {
    chat_template_kwargs = {
      enable_thinking = false;
    };
  };

  # The roles of a coding loop, as a function of the two fragments it composes. The
  # dependency is in the signature, not in the surrounding `let`, so moving either
  # binding or making `profiles` recursive cannot silently change what this captures:
  # the deploy of 2026-11-18 failed with `error: undefined variable 'noThink'` on
  # exactly that. One entry serves them all through `mkFilters`, so the values are
  # request-level: one `cmd`, one speculative preset, no reload between them. Each role
  # moves exactly one axis off the `roleBase` it is given — `instruct` is the exception:
  # it adds the thinking-off trait instead. The axis and its reason are stated on each
  # entry. `reasoning_budget` is the field the library already uses (`dry-budget-*`),
  # with no forcing message here.
  mkRoles = {roleBase, noThinkParams}: {
    # Plans. Axis: budget 6144, the larger of the two budgets this library ships,
    # because this role writes the longest single thinking block. Temperature stays
    # at `thinking`'s 1.0 — a plan explores, and the budget bounds it instead.
    planner = roleBase // {
      temperature = 1.0;
      reasoning_budget = 6144;
    };

    # Writes the code. Axis: temperature 0.6, `coding`'s value. No budget: a chain
    # forced shut mid-edit truncates the work instead of ending a loop.
    implementer = roleBase // {temperature = 0.6;};

    # Reads code and judges it. Axis: budget 4096, the smaller shipped budget, for a
    # bounded judgement; temperature is `coding`'s 0.6. The control's reviewer row is
    # 0/6 and its failures were timeouts, which is what a budget cuts.
    reviewer = roleBase // {
      temperature = 0.6;
      reasoning_budget = 4096;
    };

    # Dispatches and triages. Axis: budget 4096, at `agent`'s temperature 0.7. It is
    # the loop that repeats until it times out, and the budget is the loop brake this
    # entry relies on.
    supervisor = roleBase // {
      temperature = 0.7;
      reasoning_budget = 4096;
    };

    # Resolves a merge between two written sides. Axis: temperature 0.7, from
    # `instruct`/`agent`: it chooses between what exists instead of composing new
    # code. No budget, for the same reason as the implementer.
    integrator = roleBase // {temperature = 0.7;};

    # The only role with the thinking block closed: the `noThinkParams` argument
    # carries `chat_template_kwargs.enable_thinking = false`, the mechanism three model
    # files already serve. Reasoning off is a general-purpose variant, not a stage
    # of the coding loop, so it is a role of its own and it keeps `roleBase`: the
    # same top_k/top_p/min_p as the rest, because the spec preset in `cmd` is
    # shared. Temperature 0.7 is what the reference's `:instruct` id served and
    # what the `instruct`/`agent` family uses.
    #
    # Not the same thing as `profiles.instruct`, despite the name: that profile is
    # sampling only (temperature, top_p, presence) with reasoning left on, and it
    # is what four fork and David AU files serve. This role takes the trait, not
    # the sampling. Renaming the old profile touches seven files and is another
    # session.
    instruct = roleBase // noThinkParams // {temperature = 0.7;};
  };

  # `--flag value`, or nothing when the knob is left at the server default.
  flag = name: value:
    if value == null
    then ""
    else "${name} ${toString value}";

  renderFlags = parts:
    builtins.concatStringsSep " " (builtins.filter (part: part != "") parts);

  # One `--spec-type` value plus the draft knobs llama.cpp 0.9.0 exposes today.
  draftPath = type: {draft ? null, nMin ? null, nMax ? null, pMin ? null}:
    renderFlags [
      "--spec-type ${type}"
      (flag "-md" draft)
      (flag "--spec-draft-n-min" nMin)
      (flag "--spec-draft-n-max" nMax)
      (flag "--spec-draft-p-min" pMin)
    ];

  # The chat template `qwenTemplateArgs` points at. It is fetched from the commit
  # instead of read out of the `/models/templates/` checkout, and the bytes are the
  # same: qwen3.8-froggeric-v22.5, 28,234 B, sha256 e57684ba…5349c4b2. That
  # checkout stops being a dependency of the build, and moving to another template
  # is now a two-hash diff — this `hash` and this URL's commit — instead of a
  # `git pull` inside `/models/` that no commit here would record. The pin changes
  # no behaviour, so it needs no new CORE: the run below stands for it.
  qwenTemplate = pkgs.fetchurl {
    url = "https://huggingface.co/froggeric/Qwen-Fixed-Chat-Templates/resolve/855bffc49448e299789730ff92c9b8d834d6cc14/chat_template.jinja";
    hash = "sha256-5XaEuuQVYhGlVHPFpjvpdqQFo3q1vlrg5avx31NJxLI=";
  };
in {
  # Host invariants: offload every layer to the GPU, flash attention, one slot and
  # the Jinja chat template. Every model on this host carries them.
  deviceArgs = ''
    -ngl 99 -fa 1
    --parallel 1
    --jinja
  '';

  # Cache overhead measured on Unsloth-Qwen3.5-9B at llama.cpp 0.9.0: the default
  # 32 checkpoints hold ~1.4 GiB, four hold ~70 MiB. `--cache-ram 0` is the other
  # measured setting; a file that needs it, or that has no measurement of its own,
  # writes its flags instead of interpolating this fragment.
  checkpointArgs = ''
    --cache-ram 512 --ctx-checkpoints 4
  '';

  # Measured on Qwen3.5-9B-UD-Q4_K_XL.gguf, battery 2026-11-12 (llama.cpp 0.9.0):
  # tg64 base 11.10, `-b 256 -ub 128` won, and `-ctk f16 -ctv f16` beat every
  # quantised KV. A file inherits this only when its own header comment cites the
  # battery of its own GGUF; otherwise it writes the flags by hand, because a value
  # measured on another GGUF is not evidence for this one.
  memDefault = ''
    -b 256 -ub 128 -ctk f16 -ctv f16
  '';

  # DRY as server flags, for a model that sets it once for every request. Only
  # `--dry-allowed-length 3` is here: the files that serve 2 write the block
  # themselves, since that number is a per-GGUF value, not a default.
  dryArgs = ''
    --dry-multiplier 0.4 --dry-base 1.75 --dry-allowed-length 3 --dry-penalty-last-n 2048
  '';

  # The fixed chat template of the Qwen family (3.5/3.6/3.8): froggeric
  # qwen3.8-v22.5 over whatever template the GGUF embeds. A model adopts it when
  # its own test round runs, not before. It rests on one guarded CORE of the
  # reference model on 2026-11-17 against the pre-DRY bare id: 28 OK against 13,
  # timeouts 5 against 24, and blocked writes down to three rows, none of them an
  # evaluator pass. Caveat: `t07` regressed 2/3 → 0/3 and the sample is one CORE, so
  # it is a baseline, not a law.
  qwenTemplateArgs = ''
    --chat-template-file ${qwenTemplate}
  '';

  # Request-level sampling, one attrset per role. The values are what the files
  # already served: where two of them disagreed, the majority value is here and the
  # file overrides it with `//`.
  profiles = {
    # Reasoning on, general prompts. The default role of most files.
    thinking = {
      temperature = 1.0;
      top_p = 0.95;
      top_k = 20;
      min_p = 0.0;
      presence_penalty = 1.5;
      repeat_penalty = 1.0;
    };

    # Reasoning on, code.
    coding = {
      temperature = 0.6;
      top_p = 0.95;
      top_k = 20;
      min_p = 0.0;
      presence_penalty = 0.0;
      repeat_penalty = 1.0;
    };

    # No reasoning: a model that does not reason, or one whose chain is left alone
    # for the instruct variant.
    instruct = {
      temperature = 0.7;
      top_p = 0.8;
      top_k = 20;
      min_p = 0.0;
      presence_penalty = 1.5;
      repeat_penalty = 1.0;
    };

    # Alias of the `let`-bound `noThinkParams`: the three model files that serve this
    # filter read it here, and `roles` receives the same binding through `mkRoles`.
    # The key stays `noThink` and the binding carries the `Params` suffix, so this
    # alias is not an `x = x;` that only the set's non-recursiveness keeps from
    # looping.
    noThink = noThinkParams;

    # Agentic default of a model that samples its own agent loop.
    agent = {
      temperature = 0.7;
      top_p = 0.8;
      top_k = 20;
      min_p = 0.0;
      presence_penalty = 1.5;
      repeat_penalty = 1.1;
    };

    # The roles of a coding loop, built by `mkRoles`: the two fragments it composes
    # travel as arguments, so this key depends on nothing that surrounds it.
    roles = mkRoles {inherit roleBase noThinkParams;};

    dry = dryParams;
  };

  # `{setParamsByID = …;}` for exactly the roles it is given: `default` renders as
  # the bare `${MODEL_ID}`, every other role as `${MODEL_ID}:<role>`. A file passes
  # only the roles it serves, so no variant appears on a model that had none.
  mkFilters = roles: {
    setParamsByID = builtins.listToAttrs (map (role: {
        name =
          if role == "default"
          then "\${MODEL_ID}"
          else "\${MODEL_ID}:${role}";
        value = roles.${role};
      }) (builtins.attrNames roles));
  };

  # `dryParams` plus three roles per budget: the bare budget, the forcing message and
  # the empty message. Spread it with `//` inside `mkFilters`.
  dryVariants = {budgets ? defaultBudgets}:
    builtins.foldl'
    (roles: budget: roles // budgetRoles budget)
    {dry = dryParams;}
    budgets;

  # `--spec-*` are server flags: they go in `cmd`, never in `filters`. The knobs are
  # the ones a model file already carries; the type name is llama.cpp's. `mtp` stays
  # because live files interpolate it and its head is embedded in the GGUF they
  # serve. `eagle` was dropped because no model file interpolates it and the EAGLE3
  # entry is not written yet — the draft does exist
  # (`/models/Qwen3.5-9B-Eagle3-ShareGPT-Q4_K_M.gguf`, 272 MiB), it loads on 1.0.0
  # and measured 1.159x global at `n-max 1`, which is poison for prose and json,
  # -6.7 % on code and +861 MiB: put the fragment back when that entry is written.
  # `dspark` was dropped because no draft GGUF exists for it at all. `dflash` was
  # never here and does not belong: its draft fails to load on 1.0.0
  # (`dflash.attention.causal` type) and is not going to be reconverted.
  specArgs = {
    mtp = draftPath "draft-mtp";
  };
}
