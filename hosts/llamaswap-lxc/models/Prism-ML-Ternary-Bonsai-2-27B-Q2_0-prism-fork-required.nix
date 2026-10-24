# 300926
# 18GB VRAM: -ctk q4_0 -ctv q4_0 permite ~131K ctx
# --reasoning-effort medium: 91 think tokens vs 106 xhigh, ~+8% throughput
{llama-server}: {
  "Prism ML Ternary Bonsai 2 27B Q2_0" = {
    name = "Prism ML Ternary Bonsai 2 27B Q2_0";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Ternary-Bonsai-2-27B-Q2_0-prism-fork-required.gguf
      -ngl 99 -fa 1
      -b 256 -ub 128 -ctk f16 -ctv f16
      --ctx-size 32768
      --cache-ram 0 --ctx-checkpoints 4
      --reasoning-effort medium
      --parallel 1
      --jinja
      --reasoning-preserve
      --reasoning-format deepseek
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
