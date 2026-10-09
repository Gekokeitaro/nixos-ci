# 300926
# 18GB VRAM: -ctk q4_0 -ctv q4_0 permite ~131K ctx
# --reasoning-effort medium: 91 think tokens vs 106 xhigh, ~+8% throughput
{llama-server}: {
  "Prism ML Ternary Bonsai 2 27B PTQ1_0" = {
    name = "Prism ML Ternary Bonsai 2 27B PTQ1_0";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Ternary-Bonsai-2-27B-PTQ1_0.gguf
      --spec-type ngram-mod,draft-mtp
      --reasoning-effort medium
      -ngl 99 -fa 1
      --ctx-size 65536
      -ctk q8_0 -ctv q4_0
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
