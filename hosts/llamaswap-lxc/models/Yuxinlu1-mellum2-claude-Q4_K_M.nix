{llama-server}: {
  "Yuxinlu1 Mellum2 12B A2.5B Claude Opus Thinking Q4_K_M" = {
    name = "Yuxinlu1 Mellum2 12B A2.5B Claude Opus Thinking Q4_K_M";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/mellum2-claude-Q4_K_M.gguf
      --spec-type ngram-mod
      --n-gpu-layers 99
      --n-cpu-moe 4
      --ctx-size 65536
      --batch-size 4096
      --ubatch-size 512
      --threads 4
      --parallel 1
      --flash-attn on
      --jinja
      --fit off
      --mlock
      --no-mmap
      --no-warmup
    '';
    ttl = 600;
  };
}
