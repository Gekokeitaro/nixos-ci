# 300926
# 18GB VRAM: -ctk q4_0 -ctv q4_0 permite ~131K ctx
# --reasoning-effort medium: 91 think tokens vs 106 xhigh, ~+8% throughput
{llama-server}: {
  "Qwen3.8 27B GSQ-RCO IQ3_XXS MTP" = {
    name = "Qwen3.8 27B GSQ-RCO IQ3_XXS MTP";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Qwen3.8-27B-GSQ-RCO-IQ3_XXS-mtp.gguf
      --spec-type ngram-mod,draft-mtp
      --spec-draft-n-max 2
      --reasoning-effort medium
      -ngl 99
      -ctk q8_0 -ctv q4_0 -fa 1
      --ctx-size 131072
      --parallel 1
      --jinja
      --no-mmap
      --reasoning-preserve
      --reasoning-format deepseek
      --temp 1.0
      --top-p 0.95
      --top-k 20
      --min-p 0.0
      --presence-penalty 0.0
      -b 256 -ub 256
    '';
    ttl = 600;
  };
}
