# Model module shape

How a file under `hosts/llamaswap-lxc/models/` is built: which layer owns what,
the signature, where each flag goes, and the procedure to create one. The rules
that bind configuration are in
[`hosts/llamaswap-lxc/AGENTS.md`](../../../hosts/llamaswap-lxc/AGENTS.md); this
file is the how.

- [Layers](#layers)
- [Signature](#signature)
- [What the library owns](#what-the-library-owns)
- [What a model file owns](#what-a-model-file-owns)
- [Where each flag goes](#where-each-flag-goes)
- [Creation procedure](#creation-procedure)
- [Worked example](#worked-example)
- [Comments](#comments)
- [Archive](#archive)

## Layers

Three layers, one owner each. A value lives in exactly one of them.

| Layer | File | Owns |
|---|---|---|
| Merge | `models/default.nix` | reading the directory, skipping `archived/` and `lib/`, importing the library **once**, aborting on a duplicate id |
| Fragments | `models/lib/default.nix` | every flag and every role value that more than one model serves |
| Model | `models/<Account>-<model>-<quant>.nix` | one GGUF: its path, its context, what that GGUF measured, and the values true only for it |

`models/lib/default.nix` is a plain attrset, not a function and not a builder. It
returns text fragments and attrsets; the model file interpolates them into its own
`{ "id" = { name; cmd; filters; ttl; }; }` and stays readable as a llama-swap
entry. `models/default.nix` imports it with `import ./lib` and passes it to every
file as `modelLib`. `lib/` is a directory, and `isModelFile` only accepts regular
files, so the library is invisible to the merge.

## Signature

```nix
{llama-server, modelLib}: {
  "Model Id" = {
    name = "Model Id";
    cmd = "...";
    filters = ...;
    ttl = 600;
  };
}
```

`llama-server` is the delayed wrapper from `configuration.nix`, not the raw
server.

Forbidden in a model file:

- `pkgs`, `lib`, `with pkgs;` — the library arrives whole as `modelLib`.
- `import ./lib` — the import lives only in `models/default.nix`.
- a local `let` whose value is one fragment (`commonArgs = modelLib.deviceArgs;`).
  A `let` stays when the values are shared by the several ids of one file: the
  base `cmd` and its speculative preset.
- a helper that assembles the entry (`mkEntry`, `mkModel`) — it hides the
  rendered `cmd` from whoever reads the file next.

## What the library owns

| Fragment | Content | Use it when |
|---|---|---|
| `deviceArgs` | `-ngl 99 -fa 1`, `--parallel 1`, `--jinja` | always; it is the host invariant. A GGUF that serves without `--jinja` writes the flags it keeps by hand |
| `checkpointArgs` | `--cache-ram 512 --ctx-checkpoints 4` | the GGUF was measured with it, or it is the memory setting the file already serves |
| `memDefault` | `-b 256 -ub 128 -ctk f16 -ctv f16` | **only** when the file's own header cites the battery of its own GGUF |
| `dryArgs` | `--dry-multiplier 0.4 --dry-base 1.75 --dry-allowed-length 3 --dry-penalty-last-n 2048` | DRY is set once for the server, with `--dry-allowed-length 3` |
| `profiles.thinking` | `temperature 1.0`, `top_p 0.95`, `top_k 20`, `min_p 0.0`, `presence_penalty 1.5`, `repeat_penalty 1.0` | the reasoning-on, general role |
| `profiles.coding` | `temperature 0.6`, `top_p 0.95`, `top_k 20`, `min_p 0.0`, `presence_penalty 0.0`, `repeat_penalty 1.0` | the reasoning-on, code role |
| `profiles.instruct` | `temperature 0.7`, `top_p 0.8`, `top_k 20`, `min_p 0.0`, `presence_penalty 1.5`, `repeat_penalty 1.0` | a model that does not reason, for the instruct role |
| `profiles.noThink` | `chat_template_kwargs.enable_thinking = false` | reasoning is switched off through the template |
| `profiles.agent` | `temperature 0.7`, `top_p 0.8`, `top_k 20`, `min_p 0.0`, `presence_penalty 1.5`, `repeat_penalty 1.1` | the agentic default role of a model that samples its own loop |
| `dryParams` | `dry_multiplier 0.4`, `dry_base 1.75`, `dry_allowed_length 3`, `dry_penalty_last_n 2048`, request-level | a role composes it as a measured corrective: `roles.supervisor // dryParams` |
| `mkFilters roles` | `{setParamsByID = …}` | always, when the file has filters |
| `specArgs.mtp` | `--spec-type draft-mtp`, optional `-md`, `--spec-draft-n-min`, `--spec-draft-n-max`, `--spec-draft-p-min` | the speculative preset uses an MTP head |

There is no `specArgs` entry for a type that needs its own draft GGUF: this host has
no EAGLE or DSpark draft, and none is going to be converted. A file that serves the
`draft-mtp,ngram-mod` combo writes its `--spec-*` flags in `cmd` instead, because the
fragment renders one type.

`mkFilters` renders the key of the `default` role as the bare `${MODEL_ID}` and
every other role as `${MODEL_ID}:<role>`, so the client-id suffixes have one
owner. It only renders the roles it is given: a file that served no variant keeps
serving none.

**A DRY value and a reasoning budget are not variants.** They were served as
`:dry` and `:dry-budget-*` until 2026-11-19, seven ids per model for two knobs
every role already decides. They now live on the role: `roleBase` carries DRY 0
as the correction of this GGUF, and `planner`, `reviewer` and `supervisor` carry
their own budgets. When a measurement asks for a different pair, it is composed
into that one role (`roles.reviewer // dryParams`) and the role is re-measured —
not multiplied across the model.

### The `memDefault` rule

A file may interpolate `memDefault` **only** if its header comment cites the
battery of its own GGUF. The fragment's numbers were measured on
`Qwen3.5-9B-UD-Q4_K_XL.gguf` (battery 2026-11-12); that is evidence for that
GGUF and for nothing else. Without a battery of its own, a file writes
`-b`, `-ub`, `-ctk` and `-ctv` by hand.

The same rule covers `checkpointArgs`, `dryArgs` and the profiles: a fragment
carries the majority or measured value, never a proof about another GGUF.

## What a model file owns

- The id, unique across `models/`, and the display `name`.
- `--model` with its path under `/models/`, and the GGUF it names.
- `--ctx-size`.
- `-b`/`-ub`/`-ctk`/`-ctv` when they are not `memDefault` under the rule above.
- Sampling written as server flags (`--temp`, `--top-p`, `--top-k`, `--min-p`,
  `--repeat-penalty`, `--samplers`) and the per-role values in `filters`.
- Format flags that change the wire protocol: `--reasoning-preserve`,
  `--reasoning-format`, `--reasoning-effort`, `--chat-template-kwargs`.
- The speculative preset and its knobs.
- `ttl`, and the header comments.

## Where each flag goes

| Flag kind | Place | Why |
|---|---|---|
| host invariant (`-ngl`, `-fa`, `--parallel`, `--jinja`) | `cmd`, through `deviceArgs` | one value for the whole host |
| measured memory (`-b`, `-ub`, `-ctk`, `-ctv`) | `cmd`, through `memDefault` only under its rule | every number is per GGUF |
| context (`--ctx-size`) | `cmd`, literal | per model, and the first thing an agentic session needs |
| what one variant samples | `filters.setParamsByID` | llama-swap applies it per request, keyed by the client id |
| a flag with no request equivalent | `cmd`, literal | `cmd` is the process command line |
| DRY for every request of the model | `cmd`, through `dryArgs` | it is a server default there, not a variant |
| `--spec-*` and `-md` | `cmd` of the spec preset, never `filters` | `--spec-type` is read at load time; `setParamsByID` sends request fields to the OpenAI-compatible endpoint, so a value there is ignored |

Sampling cannot be measured in t/s: `llama-bench` has no sampler flags. Whether a
sampling change is good is judged on output quality.

## Creation procedure

1. **Fix the layers.** Decide which flags the file needs and which the library
   already owns (table above). A flag that two files would repeat belongs in
   `models/lib/default.nix`, added there first, never copied into both.
2. **Check the id is free.**

   ```bash
   git grep -n '"<Model Id>"' -- hosts/llamaswap-lxc/models
   ```

   No output means free. Two files with the same id abort evaluation through
   `lib.unionOfDisjoint` in `models/default.nix`.
3. **Name the file and stage it.** `<Account>-<model>-<quant>.nix`, where
   `Account` is the publisher account on the model card. A file that is not
   `git add`-ed does not exist for the flake.

   ```bash
   git add hosts/llamaswap-lxc/models/<file>.nix
   git ls-files --error-unmatch hosts/llamaswap-lxc/models/<file>.nix
   ```
4. **Open with the signature and the header comment.** `{llama-server, modelLib}:`
   and, above it, one line per measured fact (see Comments). No leading blank
   line.
5. **Write the `cmd` in this order:** the server and `--port ''${PORT}`, `--model`,
   the spec fragment if the base serves one, `deviceArgs`, `checkpointArgs`, the
   memory fragment, `--ctx-size`, `dryArgs`, the sampling flags, the format flags.
   Order does not reach llama.cpp, but a fixed order makes two files comparable.
6. **Decide the memory with evidence.** Cite the battery of this GGUF in the
   header; only then interpolate `memDefault`. Otherwise write the flags and the
   command that produced them.
7. **Decide the sampling per role.** Read
   [`../../sampling/SKILL.md`](../../sampling/SKILL.md) for which knob does what,
   then pick from `profiles` and override with `//` where this GGUF differs.
8. **Add the speculative preset** as a second attribute sharing the base `cmd`.
   Measure the path first: [`spec-decoding`](../../../../llama-bench-runner/skills/spec-decoding/SKILL.md).
9. **Verify without `nix`.** The GGUF is on the host, the file is tracked, the id
   is unique:

   ```bash
   ssh <host> ls /models/<gguf>
   git ls-files --error-unmatch hosts/llamaswap-lxc/models/<file>.nix
   git grep -n '"<Model Id>"' -- hosts/llamaswap-lxc/models
   ```
10. **Deploy.** Push the branch `llamaswap-rocm`: the workflow runs
    `nixos-rebuild test`, which activates the configuration without making it the
    boot default. On the host, find the rendered config and read the entry:

    ```bash
    ssh <host> systemctl show llama-swap -p ExecStart   # the -config path
    ssh <host> grep -A3 '<Model Id>' <config path>
    ```

    Compare that `cmd` with the file. When it matches, push to `main`.

## Worked example

A model with `memDefault`, three roles, the DRY budget variants, DRY as a server
flag and an MTP preset. Every line is explained beside it.

```nix
# Battery 2026-11-12 (llama.cpp 0.9.0): tg64 base 11.10, guards 10.55-11.66.
# Winner: -b 256 -ub 128 -ctk f16 -ctv f16.
# Spec bench 2026-11-14: --spec-draft-n-max 2 beats 3 at temp 1 (+22 %).
{llama-server, modelLib}: let
  # Shared by the base id and its preset: everything but the spec flags.
  commonCmd = ''
    ${llama-server} --port ''${PORT}
    --model /models/<file>.gguf
    ${modelLib.deviceArgs}
    ${modelLib.checkpointArgs}
    ${modelLib.memDefault}
    --ctx-size 65536
    ${modelLib.dryArgs}
  '';

  # The three roles this model serves: no id is added for DRY or a budget.
  commonFilters = modelLib.mkFilters {
    default = modelLib.profiles.thinking;
    coding = modelLib.profiles.coding;
    instruct = modelLib.profiles.instruct;
  };
in {
  "Model Id" = {
    name = "Model Id"; # Ids are the API name; `name` is what the list shows.

    cmd = commonCmd;

    filters = commonFilters;
    ttl = 600; # Seconds the model stays loaded before llama-swap unloads it.
  };

  "Model Id MTP" = {
    name = "Model Id (MTP)";

    cmd = ''
      ${commonCmd}
      ${modelLib.specArgs.mtp {nMax = 2;}}
    '';

    filters = commonFilters;
    ttl = 600;
  };
}
```

The header is the first two facts a reader needs: what this GGUF measured and
what won. `memDefault` appears because that header cites this GGUF's battery; a
file without one writes the four flags. The preset only adds
`--spec-type draft-mtp --spec-draft-n-max 2` to the same `cmd`.

## Comments

English, one fact per line, no leading blank line:

```nix
# <ISO date> <what was measured, on which GGUF, at which llama.cpp version>
```

A comment that cites a benchmark of a different GGUF is worse than no comment:
it makes the file look measured. Delete it and say `# No battery recorded for
this GGUF.` A rule that holds for the whole host is not a comment — it belongs in
the library or in the host `AGENTS.md`.

## Archive

```bash
git mv hosts/llamaswap-lxc/models/<file>.nix hosts/llamaswap-lxc/models/archived/<file>.nix
```

Nothing else. The file is no longer served, stays in the repository for
reference, and keeps its content as it was.
