{llama-server}: {
  "LFM2.5-8B-A1B-UD-Q4_K_XL" = {
    name = "LFM2.5 8B A1B UD Q4_K_XL";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/LFM2.5-8B-A1B-UD-Q4_K_XL.gguf
      #--model-draft /models/LFM2.5-350M.Q4_K_M.gguf
      #--spec-type draft-simple
      --n-gpu-layers 99
      --ctx-size 32768
      --batch-size 2048
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
