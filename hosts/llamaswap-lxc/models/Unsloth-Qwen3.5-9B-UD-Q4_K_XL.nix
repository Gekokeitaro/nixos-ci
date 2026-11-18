# Spec bench 2026-11-17 (llama.cpp 1.0.0, this GGUF, prose/code/json at the deployed
# temp): `--spec-type draft-mtp` with `n-max 1` is 1.311x global — prose 1.215, code
# 1.420, json 1.312, acceptance 0.7383, RSS 9219 MiB. Adding `ngram-mod` at 24:32:64
# takes it to 1.359x — prose 1.223, code 1.894, json 1.609, acceptance 0.5875, RSS
# 9555 MiB, +336 MiB over MTP alone. The combo is what the file serves, and it is the
# only MTP implementation it carries: no second entry with MTP alone.
# Context 2026-11-17 (llama.cpp 1.0.0, this GGUF): the ceiling measures 217088 tokens
# with a margin of 135 MiB (VmHWM 14201 against an allowance of 14336), so the served
# window is the largest 32k multiple under it, 196608, with `--ctx-checkpoints 4` kept
# — at 192k the cache plateaus, +83 MiB over 8 turns of 256 tokens. Load peak
# 13469 MiB, and 13998 MiB with the cache full at 192k. Cold load 10.13 s median, 2 s
# of which is `llama-server-delayed`.
# Battery 2026-11-12 (llama.cpp 0.9.0): tg64 base 11.10, guards 10.55-11.66, peak VRAM+GTT 5541-9809 MiB.
# Winner: -b 256 -ub 128 -ctk f16 -ctv f16, the memory flags below. One run of the four
# b/ub pairs: pp512/pp4096 169.64/164.38 at d0 and 135.01/134.04 at d16384, tg128
# 11.56 and 10.60. -b 2048 -ub 512 loses 2.8-4.3% of pp in that same process and
# gains nothing on tg.
# KV quantisation costs 11-19% of tg at d16384 (q8_0/q4_0 9.49, f16/q8_0 8.58 vs f16/f16 10.60).
# Copy fidelity 2026-11-16 (llama.cpp 1.0.0, 10 reps per arm, this GGUF): the
# deployed chain copied a 130-char tool path 0/10 times, dry_multiplier 0 with
# everything else unchanged 10/10, presence_penalty 0 with DRY on 0/10, greedy with
# every penalty off 10/10 and greedy with DRY 0.4 0/10. DRY corrupts (`500_AI` →
# `501_AI`, `solution.js` → `solution_js`); presence is not the cause but it taxes
# the same repeated tokens, so both go to 0. DRY was also the loop brake: loop
# control now rests on reasoning_budget and max_tokens.
# Fixed template since 2026-11-17: the entry serves froggeric qwen3.8-v22.5 through
# `modelLib.qwenTemplateArgs` instead of the GGUF's embedded template, with `--jinja`
# kept and no `--reasoning-format` added. The measurement that moved it, and its
# caveat, live in that fragment.
{llama-server, modelLib}: {
  "Unsloth Qwen3.5 9B UD Q4_K_XL" = {
    name = "Unsloth Qwen3.5 9B UD Q4_K_XL";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Qwen3.5-9B-UD-Q4_K_XL.gguf
      --spec-type draft-mtp,ngram-mod --spec-draft-n-max 1
      --spec-ngram-mod-n-match 24 --spec-ngram-mod-n-min 32 --spec-ngram-mod-n-max 64
      ${modelLib.deviceArgs}
      ${modelLib.checkpointArgs}
      ${modelLib.memDefault}
      --ctx-size 196608
      ${modelLib.dryArgs}
      ${modelLib.qwenTemplateArgs}
    '';

    # One entry, seven client ids: the bare id is the measured default and holds the
    # control of 2026-11-18, untouched; the six roles are request-level filters
    # (`modelLib.profiles.roles`), so switching between them reloads nothing. The
    # `:coding` id this entry used to serve is dropped because it is byte-identical to
    # `:implementer` (`profiles.coding // {dry_multiplier = 0.0;}` states the same
    # seven keys as `roles.implementer`), while `:instruct` comes back as a role with
    # reasoning off through `chat_template_kwargs`. Values, axes and reasons are in
    # `lib/default.nix`.
    filters = modelLib.mkFilters (modelLib.profiles.roles // {
      default =
        modelLib.profiles.thinking
        // {
          dry_multiplier = 0.0;
          presence_penalty = 0.0;
        };
    });

    ttl = 600;
  };
}
