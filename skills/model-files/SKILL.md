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

## Add a model

- [ ] create `models/<Account>-<model>-<quant>.nix` opening with
      `{llama-server, modelLib}:` and a header comment
- [ ] `git add` the file and confirm it with `git ls-files --error-unmatch`
- [ ] put the GGUF under `/models/` on the host
- [ ] optional: add the `"… MTP"` attribute beside the model, sharing the base
      `cmd`
- [ ] check the id is free: `git grep -n '"<id>"' -- hosts/llamaswap-lxc/models`
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
