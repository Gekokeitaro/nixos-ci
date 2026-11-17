# Spec bench 2026-11-14 (llama.cpp 0.9.0, 192 tok, 3 reps x prose/code/json, seed 42):
# --spec-draft-n-max 2 wins: 18.15 t/s vs 11.36 without MTP at temp 0 (+60 %), and
# 13.91 vs 11.39 at the deployed temp 1 (+22 %), where prose is neutral and code
# reaches 1.63x. n-max 3 is the old default: it ties at temp 0 and loses 14 % of
# prose at temp 1. n-max 8 ties globally at temp 0 only by trading 10 % of prose.
# Battery 2026-11-12 (llama.cpp 0.9.0): tg64 base 11.10, guards 10.55-11.66, peak VRAM+GTT 5541-9809 MiB.
# Winner: -b 256 -ub 128 -ctk f16 -ctv f16, the preset below. One run of the four
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
      ${modelLib.specArgs.mtp {nMax = 2;}}
      ${modelLib.deviceArgs}
      ${modelLib.checkpointArgs}
      ${modelLib.memDefault}
      --ctx-size 65536
      ${modelLib.dryArgs}
      ${modelLib.qwenTemplateArgs}
    '';

    filters = modelLib.mkFilters {
      default =
        modelLib.profiles.thinking
        // {
          dry_multiplier = 0.0;
          presence_penalty = 0.0;
        };
      coding = modelLib.profiles.coding // {dry_multiplier = 0.0;};
      instruct = modelLib.profiles.instruct // {dry_multiplier = 0.0;};
    };

    ttl = 600;
  };
}
