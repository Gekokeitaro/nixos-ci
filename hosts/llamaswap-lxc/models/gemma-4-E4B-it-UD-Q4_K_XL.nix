{llama-server}: {
  "gemma-4-E4B-it-UD-Q4_K_XL" = {
    name = "Gemma4 E4B it UD Q4_K_XL";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/gemma-4-E4B-it-UD-Q4_K_XL.gguf
      --ctx-size 32768
      --batch-size 256
      --ubatch-size 128
      --threads 8
      --n-gpu-layers 0
      --device none
      --cache-type-k q8_0
      --cache-type-v q4_0
      --flash-attn on
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
