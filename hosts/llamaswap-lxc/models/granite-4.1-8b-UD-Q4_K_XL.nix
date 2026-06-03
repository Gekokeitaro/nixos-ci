{llama-server}: {
  "granite-4.1-8b-UD-Q4_K_XL" = {
    name = "Granite 4.1 8B UD Q4_K_XL";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/granite-4.1-8b-UD-Q4_K_XL.gguf
      --n-gpu-layers 99
      --ctx-size 32768
      --batch-size 1024
      --ubatch-size 1024
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
