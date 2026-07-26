{llama-server}: {
  "Gemma-4-19B.i1-Q4_K_M" = {
    name = "Gemma-4-19B.i1-Q4_K_M";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Gemma-4-19B.i1-Q4_K_M.gguf
      --n-gpu-layers 99
      --ctx-size 32768
      --batch-size 512
      --ubatch-size 512
      --threads 1
      --parallel 1
      --jinja
      --fit off
      --no-warmup
    '';
    ttl = 600;
  };
}
