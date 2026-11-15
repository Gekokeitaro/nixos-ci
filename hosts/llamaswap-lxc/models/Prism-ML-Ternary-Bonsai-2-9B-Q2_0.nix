# 300926
# 18GB VRAM: -ctk q4_0 -ctv q4_0 allows ~131K ctx
# --reasoning-effort medium: 91 think tokens vs 106 xhigh, ~+8% throughput
{llama-server, modelLib}: {
  "Prism ML Ternary Bonsai 2 9B Q2_0" = {
    name = "Prism ML Ternary Bonsai 2 9B Q2_0";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Ternary-Bonsai-2-9B-Q2_0.gguf
      --spec-type ngram-mod
      ${modelLib.deviceArgs}
      -b 256 -ub 128 -ctk f16 -ctv f16
      --ctx-size 65536
      --dry-multiplier 0.4 --dry-base 1.75 --dry-allowed-length 2 --dry-penalty-last-n 2048
    '';

    filters = modelLib.mkFilters {
      default = modelLib.profiles.thinking;
      coding = modelLib.profiles.coding;
      instruct = modelLib.profiles.instruct;
    };

    ttl = 600;
  };
}
