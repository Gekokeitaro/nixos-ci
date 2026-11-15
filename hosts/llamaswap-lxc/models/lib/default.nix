# Fragments shared by the model files in models/. A plain attrset, not a
# function: models/default.nix imports it once and passes it to every file as
# `modelLib`. A model file never imports it itself.
#
# The convention is owned by skills/model-files/references/module-shape.md.
let
  # Request-level DRY parameters. The same four numbers reach llama.cpp as
  # `--dry-*` server flags through `dryArgs`, or per request through a filter.
  dry = {
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
    "dry-budget-${label}" = dry // {reasoning_budget = budget;};
    "dry-budget-${label}-msg" = dry // {
      reasoning_budget = budget;
      reasoning_budget_message = "Enough think. Act now. Finish task. No loops.";
    };
    "dry-budget-${label}-empty-msg" = dry // {
      reasoning_budget = budget;
      reasoning_budget_message = "...";
    };
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

    # Reasoning off through the chat template, not through a sampling value. The
    # server defaults carry the sampling; this only closes the thinking block.
    noThink = {
      chat_template_kwargs = {
        enable_thinking = false;
      };
    };

    # Agentic default of a model that samples its own agent loop.
    agent = {
      temperature = 0.7;
      top_p = 0.8;
      top_k = 20;
      min_p = 0.0;
      presence_penalty = 1.5;
      repeat_penalty = 1.1;
    };

    dry = dry;
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

  # `dry` plus three roles per budget: the bare budget, the forcing message and the
  # empty message. Spread it with `//` inside `mkFilters`.
  dryVariants = {budgets ? defaultBudgets}:
    builtins.foldl'
    (roles: budget: roles // budgetRoles budget)
    {dry = dry;}
    budgets;

  # `--spec-*` are server flags: they go in `cmd`, never in `filters`. The knobs are
  # the ones a model file already carries; the type name is llama.cpp's.
  specArgs = {
    mtp = draftPath "draft-mtp";
    eagle = draftPath "draft-eagle3";
    dspark = draftPath "draft-dspark";
  };
}
