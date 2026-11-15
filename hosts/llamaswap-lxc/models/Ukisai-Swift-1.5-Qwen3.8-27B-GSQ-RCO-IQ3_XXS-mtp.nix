# 300926
# 18GB VRAM: -ctk q4_0 -ctv q4_0 allows ~131K ctx
# --reasoning-effort medium: 91 think tokens vs 106 xhigh, ~+8% throughput
{llama-server, modelLib}: {
  "Ukisai Swift 1.5 Qwen3.8 27B GSQ RCO IQ3_XXS mtp" = {
    name = "Ukisai Swift 1.5 Qwen3.8 27B GSQ RCO IQ3_XXS mtp";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Swift-1.5-Qwen3.8-27B-GSQ-RCO-IQ3_XXS-mtp.gguf
      ${modelLib.deviceArgs}
      --cache-ram 0 --ctx-checkpoints 4
      -b 256 -ub 128 -ctk f16 -ctv f16
      --ctx-size 32768
      --reasoning-preserve
      --reasoning-format deepseek
      --reasoning-effort medium
    '';

    filters = modelLib.mkFilters {
      default = modelLib.profiles.thinking // {presence_penalty = 0.0;};
      instruct = modelLib.profiles.instruct;
    };

    ttl = 600;
  };
}
