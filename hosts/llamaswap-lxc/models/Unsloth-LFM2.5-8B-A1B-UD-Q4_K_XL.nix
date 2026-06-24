{llama-server}: {
  "Unsloth LFM2.5 8B A1B UD" = {
    name = "Unsloth LFM2.5 8B A1B UD";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/LFM2.5-8B-A1B-UD-Q4_K_XL.gguf
      --spec-type ngram-mod
      --n-gpu-layers 99
      --ctx-size 32768
      --threads 8
      --parallel 1
      --flash-attn on
      --jinja
      --fit off
      --no-mmap
      --no-warmup
    '';
    ttl = 600;
  };
}
