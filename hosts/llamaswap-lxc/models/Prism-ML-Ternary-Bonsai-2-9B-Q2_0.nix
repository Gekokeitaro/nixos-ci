# 300926
# 18GB VRAM: -ctk q4_0 -ctv q4_0 permite ~131K ctx
# --reasoning-effort medium: 91 think tokens vs 106 xhigh, ~+8% throughput
{llama-server}: {
  "Prism ML Ternary Bonsai 2 9B Q2_0" = {
    name = "Prism ML Ternary Bonsai 2 9B Q2_0";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Ternary-Bonsai-2-9B-Q2_0.gguf
      --spec-type ngram-mod
      -ngl 99 -fa 1
      -b 256 -ub 128 -ctk f16 -ctv f16
      --dry-multiplier 0.8 --dry-base 1.75 --dry-allowed-length 2 --dry-penalty-last-n 2048
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
