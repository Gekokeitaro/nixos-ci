# 300926
# 18GB VRAM: -ctk q4_0 -ctv q4_0 allows ~131K ctx
# --reasoning-effort medium: 91 think tokens vs 106 xhigh, ~+8% throughput
{llama-server, modelLib}: {
  "Prism ML Ternary Bonsai 2 27B Q2_0" = {
    name = "Prism ML Ternary Bonsai 2 27B Q2_0";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Ternary-Bonsai-2-27B-Q2_0-prism-fork-required.gguf
      ${modelLib.deviceArgs}
      --cache-ram 0 --ctx-checkpoints 4
      -b 256 -ub 128 -ctk f16 -ctv f16
      --ctx-size 32768
      --dry-multiplier 0.4 --dry-base 1.75 --dry-allowed-length 2 --dry-penalty-last-n 2048
      --reasoning-preserve
      --reasoning-format deepseek
    '';

    filters = modelLib.mkFilters {
      default = modelLib.profiles.thinking // {presence_penalty = 0.0;};
      instruct = modelLib.profiles.instruct;
    };

    ttl = 600;
  };
}
