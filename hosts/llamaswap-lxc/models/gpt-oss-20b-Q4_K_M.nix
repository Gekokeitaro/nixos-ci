{llama-server}: {
  "gpt-oss-20b-Q4_K_M" = {
    name = "gpt-oss-20b-Q4_K_M";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/gpt-oss-20b-Q4_K_M.gguf
      --ctx-size 32768
      --n-gpu-layers 99
      --threads 2
      --flash-attn 1
      --batch-size 1024
      --ubatch-size 512
      --mmap 1
      --parallel 1
      --fit off
      --no-warmup
    '';
    ttl = 600;
  };
}
