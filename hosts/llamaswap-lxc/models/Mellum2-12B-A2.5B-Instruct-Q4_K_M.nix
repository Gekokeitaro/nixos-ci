{llama-server}: {
  "Mellum2-12B-A2.5B-Instruct-Q4_K_M" = {
    name = "Mellum2-12B-A2.5B-Instruct-Q4_K_M";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Mellum2-12B-A2.5B-Instruct-Q4_K_M.gguf
      --n-gpu-layers 99
      --n-cpu-moe 16
      --ctx-size 32768
      --batch-size 4096
      --ubatch-size 512
      --threads 4
      --parallel 1
      --flash-attn on
      --jinja
      --fit off
      --no-warmup
    '';
    ttl = 600;
  };
}
