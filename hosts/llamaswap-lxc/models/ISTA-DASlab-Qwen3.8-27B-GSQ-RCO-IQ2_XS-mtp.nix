# 300926
# 18GB VRAM: -ctk q4_0 -ctv q4_0 permite ~131K ctx
# --reasoning-effort medium: 91 think tokens vs 106 xhigh, ~+8% throughput
{llama-server}: {
  "ISTA-DASlab Qwen3.8 27B GSQ-RCO IQ2_XS MTP" = {
    name = "ISTA-DASlab Qwen3.8 27B GSQ-RCO IQ2_XS MTP";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Qwen3.8-27B-GSQ-RCO-IQ2_XS-mtp.gguf
      --spec-type draft-mtp
      --reasoning-effort medium
      -ngl 99 -fa 1
      -ctk q8_0 -ctv q4_0
      --ctx-size 65536
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
