{llama-server}: {
  "gemma-4-E4B-it-UD-Q4_K_XL" = {
    name = "Gemma4 E4B it UD Q4_K_XL";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/gemma-4-E4B-it-UD-Q4_K_XL.gguf
      --ctx-size 65536
      --batch-size 512
      --ubatch-size 512
      --threads 1
      --n-gpu-layers 999
      --flash-attn on
      --cache-type-k q8_0
      --cache-type-v q4_1
      --swa-full
      --temp 0.1
      --top-p 0.9
      --top-k 40
      --repeat-penalty 1.1
      --jinja
      --reasoning off
      --fit off
      --parallel 1
    '';
    ttl = 600;
  };
}
