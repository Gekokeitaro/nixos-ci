{llama-server}: {
  "gemma-4-E4B-it-UD-Q4_K_XL" = {
    name = "Gemma4 E4B it UD Q4_K_XL";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/gemma-4-E4B-it-UD-Q4_K_XL.gguf
      --n-gpu-layers 99
      --ctx-size 65536
      --batch-size 4096
      --ubatch-size 512
      --threads 4
      --parallel 1
      --flash-attn on
      --swa-full
      --jinja
      --reasoning off
      --fit off
      --no-warmup
    '';
    ttl = 600;
  };
}
