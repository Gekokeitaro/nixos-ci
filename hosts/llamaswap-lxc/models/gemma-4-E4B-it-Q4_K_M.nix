{llama-server}: {
  "gemma-4-E4B-it-Q4_K_M" = {
    name = "gemma-4-E4B-it-Q4_K_M";
    cmd = ''
      ''${llama-server} --port ''${PORT}
      --model /models/gemma-4-E4B-it-Q4_K_M.gguf
      --ctx-size 8192
      --batch-size 512
      --ubatch-size 512
      --threads 1
      --n-gpu-layers 999
      --cache-type-k q8_0
      --cache-type-v q4_1
      --temp 0.1
      --top-p 0.9
      --top-k 40
      --repeat-penalty 1.1
      --jinja
      --fit off
      --parallel 1
    '';
    ttl = 600;
  };
}
