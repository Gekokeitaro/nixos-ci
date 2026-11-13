# Battery 2026-11-12 (llama.cpp 0.9.0): tg64 base 11.10, guards 10.55-11.66, peak VRAM+GTT 5541-9809 MiB.
# Winner: -b 256 -ub 128 -ctk f16 -ctv f16, the preset below. One run of the four
# b/ub pairs: pp512/pp4096 169.64/164.38 at d0 and 135.01/134.04 at d16384, tg128
# 11.56 and 10.60. -b 2048 -ub 512 loses 2.8-4.3% of pp in that same process and
# gains nothing on tg.
# KV quantisation costs 11-19% of tg at d16384 (q8_0/q4_0 9.49, f16/q8_0 8.58 vs f16/f16 10.60).
{llama-server}: {
  "Unsloth Qwen3.5 9B UD Q4_K_XL" = {
    name = "Unsloth Qwen3.5 9B UD Q4_K_XL";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Qwen3.5-9B-UD-Q4_K_XL.gguf
      --spec-type draft-mtp
      -ngl 99 -fa 1
      -b 256 -ub 128 -ctk f16 -ctv f16
      --dry-multiplier 0.4 --dry-base 1.75 --dry-allowed-length 3 --dry-penalty-last-n 2048
      --ctx-size 65536
      --parallel 1
      --jinja
    '';

    filters = {
      setParamsByID = {
        # Thinking — general
        "\${MODEL_ID}" = {
          temperature = 1.0;
          top_p = 0.95;
          top_k = 20;
          min_p = 0.0;
          presence_penalty = 1.5;
          repeat_penalty = 1.0;
        };

        # Thinking — coding
        "\${MODEL_ID}:coding" = {
          temperature = 0.6;
          top_p = 0.95;
          top_k = 20;
          min_p = 0.0;
          presence_penalty = 0.0;
          repeat_penalty = 1.0;
        };

        # Instruct — general
        "\${MODEL_ID}:instruct" = {
          temperature = 0.7;
          top_p = 0.8;
          top_k = 20;
          min_p = 0.0;
          presence_penalty = 1.5;
          repeat_penalty = 1.0;
        };
      };
    };

    ttl = 600;
  };
}
