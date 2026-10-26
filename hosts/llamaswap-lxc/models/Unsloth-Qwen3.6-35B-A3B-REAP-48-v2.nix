# 300926
# 18GB VRAM: -ctk q4_0 -ctv q4_0 permite ~131K ctx
# --reasoning-effort medium: 91 think tokens vs 106 xhigh, ~+8% throughput
{llama-server}: {
  "Unsloth Qwen3.6 35B A3B REAP 48 v2" = {
    name = "Unsloth Qwen3.6 35B A3B REAP 48 v2";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Qwen3.6-35B-A3B-REAP-48-v2.gguf
      -ngl 99 -t 1
      -b 2048 -ub 512 -ctk f16 -ctv f16 -fa 1 
      --ctx-size 32768
      --cache-ram 0 --ctx-checkpoints 4
      --dry-multiplier 0.8 --dry-base 1.75 --dry-allowed-length 2 --dry-penalty-last-n -1
      --parallel 1
      --jinja
      --reasoning-preserve
      --reasoning-format deepseek
    '';

    filters = {
      setParamsByID = {
        # Agent - general
        "\${MODEL_ID}" = {
          temperature = 0.7;
          top_p = 0.8;
          top_k = 20;
          min_p = 0.0;
          presence_penalty = 1.5;
          repeat_penalty = 1.1;
        };

        # Thinking
        "\${MODEL_ID}:thinking" = {
          temperature = 1.0;
          top_p = 0.95;
          top_k = 20;
          min_p = 0.0;
          presence_penalty = 1.5;
          repeat_penalty = 1.1;
        };
        
        # Coding
        "\${MODEL_ID}:coding" = {
          temperature = 0.6;
          top_p = 0.95;
          top_k = 20;
          min_p = 0.0;
          presence_penalty = 0.0;
          repeat_penalty = 1.0;
        };
      };
    };

    ttl = 600;
  };
}
