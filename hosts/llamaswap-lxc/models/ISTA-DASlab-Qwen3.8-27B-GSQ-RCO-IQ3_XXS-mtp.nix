# 300926
# 18GB VRAM: -ctk q4_0 -ctv q4_0 permite ~131K ctx
# --reasoning-effort medium: 91 think tokens vs 106 xhigh, ~+8% throughput
{llama-server}: {
  "ISTA-DASlab Qwen3.8 27B GSQ-RCO IQ3_XXS MTP" = {
    name = "ISTA-DASlab Qwen3.8 27B GSQ-RCO IQ3_XXS MTP";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Qwen3.8-27B-GSQ-RCO-IQ3_XXS-mtp.gguf
      --spec-type draft-mtp,ngram-mod
      --spec-draft-n-max 2 --spec-draft-p-min 0.6
      --reasoning-effort low
      -ngl 99 -fa 1
      -ctk q4_0 -ctv q4_0
      --ctx-size 49152
      --parallel 1
      --jinja
      --reasoning-preserve
      --reasoning-format deepseek
      --cache-ram 2048 --ctx-checkpoints 8
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
