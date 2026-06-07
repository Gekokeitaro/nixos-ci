{llama-server}: {
  "gemma-4-12B-it-qat-UD-Q4_K_XL" = {
    name = "gemma-4-12B-it-qat-UD-Q4_K_XL";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/gemma-4-12B-it-qat-UD-Q4_K_XL.gguf
      --spec-type draft-mtp
      --spec-draft-n-max 4
      --n-gpu-layers 99
      --ctx-size 32768
      --batch-size 2048
      --ubatch-size 1024
      --threads 1
      --parallel 1
      --flash-attn on
      --jinja 
      --fit off
      --no-warmup
    '';
    ttl = 600;
  };
}
