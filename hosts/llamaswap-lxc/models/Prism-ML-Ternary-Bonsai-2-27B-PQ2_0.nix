# 300926
# 18GB VRAM: -ctk q4_0 -ctv q4_0 permite ~131K ctx
# --reasoning-effort medium: 91 think tokens vs 106 xhigh, ~+8% throughput
{llama-server}: {
  "Prism ML Ternary Bonsai 2 27B PQ2_0" = {
    name = "Prism ML Ternary Bonsai 2 27B PQ2_0";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Ternary-Bonsai-2-27B-PQ2_0.gguf
      --spec-type ngram-mod,draft-mtp
      --reasoning-effort medium
      -ngl 99
      --ctx-size 65536
      --kv-unified -fa 1
      --parallel 1
      --jinja
      --reasoning-preserve
      --reasoning-format deepseek
      --temp 1.0
      --top-p 0.95
      --top-k 20
      --min-p 0.0
      --presence-penalty 0.0
    '';
    ttl = 600;
  };
}
