# 300926
# 18GB VRAM: -ctk q4_0 -ctv q4_0 permite ~131K ctx
# --reasoning-effort medium: 91 think tokens vs 106 xhigh, ~+8% throughput
{llama-server}: {
  "Ukisai Swift 1.5 Qwen3.8 27B GSQ RCO IQ3_XXS mtp" = {
    name = "Ukisai Swift 1.5 Qwen3.8 27B GSQ RCO IQ3_XXS mtp";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Swift-1.5-Qwen3.8-27B-GSQ-RCO-IQ3_XXS-mtp.gguf
      -ngl 99 -fa 1
      -b 256 -ub 128 -ctk f16 -ctv f16
      --ctx-size 32768
      --cache-ram 0 --ctx-checkpoints 4
      --parallel 1
      --jinja
      --reasoning-preserve
      --reasoning-format deepseek
      --reasoning-effort medium
    '';

    filters = {
      setParamsByID = {
        # Thinking — general
        "\${MODEL_ID}" = {
          temperature = 1.0;
          top_p = 0.95;
          top_k = 20;
          min_p = 0.0;
          presence_penalty = 0.0;
          repeat_penalty = 1.0;
        };

        # Instruct
        "\${MODEL_ID}:instruct" = {
          temperature = 0.7;
          top_p = 0.80;
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
