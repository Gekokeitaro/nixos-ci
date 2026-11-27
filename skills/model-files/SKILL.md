---
name: model-files
description: Creates, renames and archives the model entries under `models/` on the llama-swap host — the `.nix` signature, the shared fragment library, the GGUF under `/models/`, the `git add` a flake requires, and where a speculative preset attribute goes. Use when adding a GGUF or a model to `models/`, renaming or archiving a served model, when `nixos-rebuild` cannot see a file you just wrote, or when two model ids collide — even if the request is only "archive Qwen3.5 9B". Not for what an entry samples — the sampler chain, `--temp`, `filters` and `reasoning_budget` belong to the sampling skill.
---

# Model files

One `.nix` file per model in `hosts/llamaswap-lxc/models/`. `models/default.nix`
merges every regular `.nix` file in that directory, skips `archived/` and `lib/`,
and imports the shared fragments once. No list in `configuration.nix` is edited.

The shape is owned by [`references/module-shape.md`](references/module-shape.md):
the three layers, the `{llama-server, modelLib}:` signature, which fragment owns
which flag, the creation procedure step by step and a full example. Read it
before writing a file; this page keeps only the gotchas and the checklist.

## Gotchas

- A model file that is not `git add`-ed does not exist for the flake: the build
  copies the Git tree, so an untracked `models/*.nix` is silently absent.
- Two files defining the same model id abort evaluation through
  `lib.unionOfDisjoint` in `models/default.nix`.
- `--spec-*` is a server flag and cannot travel through `filters.setParamsByID`:
  it goes in the `cmd` of the second attribute, or it is ignored.
- `modelLib` is an argument, not an import. A model file never writes
  `import ./lib` and never repeats a fragment the library already holds.

## Composition scope

A plain attribute set literal is not recursive: in `{a = 1; b = a;}` the `a`
inside `b` is not in scope. Four mechanisms put a name there, and the criterion
separates them:

| Mechanism | Use when | In this repo |
|---|---|---|
| `let` binding | a constant several fragments share; the value is in scope everywhere in the file | `roleBase`, `noThinkParams`, `dryParams` |
| builder function | a fragment composes another: take it as a parameter, so the dependency sits in the signature instead of the surrounding scope | `budgetRoles = {label, budget}:`, `dryVariants = {budgets ? …}:`, `mkFilters = roles:`, `mkRoles = {roleBase, noThinkParams}:`, `overrideAttrs (oldAttrs: …)` |
| `rec { … }` | the set genuinely refers to itself | not used here: `packages/llama-cpp/default.nix` dropped its `rec` when the pins moved to `versions.nix` |
| `lib.fix (self: …)` | a self-referential set that must also stay overridable | not used here; `lib.fix` appears nowhere in this repo |

The dominant idiom is the builder, so a fragment that composes another takes it as
an argument rather than closing over it: `roles` is
`mkRoles = {roleBase, noThinkParams}: …`, and `profiles.roles` binds it with
`mkRoles {inherit roleBase noThinkParams;}`. The dependency is visible in the
signature, so moving either binding or making the surrounding set `rec` cannot
silently change what it captures.

`rec` costs two things. An alias `x = x;` inside it becomes a self-reference and
Nix fails with infinite recursion. A set later extended with `//` does not
participate in the recursion, so an override loses access to the recursive names.

`profiles` carries `dry = dryParams;` and `noThink = noThinkParams;`: the keys stay
as the model files read them, and the `let` binding each one aliases carries the
`Params` suffix, so neither line has an `x = x;` shape to turn into a self-reference
under `rec`. The deploy of 2026-11-18 failed with `error: undefined variable
'noThink'` because `profiles.roles.instruct` composed a sibling key; `roleBase` had
worked only because it lived in the `let`.

## LoRA adapters

An adapter rides on a served GGUF and goes in the same `cmd`:
`--lora /models/<file>.gguf` at scale 1.0, or `--lora-scaled /models/<file>.gguf:0.8` when a scale
is being chosen. It applies to **every role of that entry** (the roles are request-level filters),
it costs generation throughput, and it is not versioned by Git — quote its `sha256` next to any
measurement. Compatibility is by `general.architecture`, not by the derivative's name. Loading,
the scale-0/scale-1 A/B, and the Qwen3.8 27B targets:
[`references/lora-adapters.md`](references/lora-adapters.md).

## Add a model

- [ ] create `models/<Account>-<model>-<quant>.nix` opening with
      `{llama-server, modelLib}:` and a header comment
- [ ] `git add` the file and confirm it with `git ls-files --error-unmatch`
- [ ] put the GGUF under `/models/` on the host
- [ ] optional: add the `"… MTP"` attribute beside the model, sharing the base
      `cmd`
- [ ] check the id is free: `git grep -n '"<id>"' -- hosts/llamaswap-lxc/models`
- [ ] a fragment composed by another fragment lives in the `let`; a sibling alias
      `x = x;` inside `profiles` is what forbids making it `rec`
- [ ] no `x = x;` in an attrset: if the enclosing `let` binding and the key would
      share a name, rename the binding; the alias reads as self-reference and
      becomes one under `rec`
- [ ] deploy the procedure's way; the ROCm host runs it from `main`

- **Naming.** The first token is the publisher's account (`DavidAU`, `Unsloth`,
  `JetBrains`…); follow the files already there. That account is where the model
  card lives.
- **Signature.** `${llama-server}` is the delayed wrapper, not the raw server.
  `modelLib` is the fragment library, injected by `models/default.nix`.
- **`/models/`.** An external Proxmox bind mount, not part of this repository.
- **Preset.** A second attribute; `Unsloth-gemma-4-12B-it-qat-UD-Q4_K_XL.nix` is
  the shape (the rule is in the host `AGENTS.md`). Read
  [`../sampling/SKILL.md`](../sampling/SKILL.md) before choosing the chain, and
  [`spec-decoding`](../../../llama-bench-runner/skills/spec-decoding/SKILL.md)
  before choosing the path.

The last two checklist lines are the gate: an untracked file and a duplicate id
surface only at deploy.

## Archive a model

Move the file to `models/archived/`. It stays in the repository for reference, is
no longer served, and needs no other edit.
