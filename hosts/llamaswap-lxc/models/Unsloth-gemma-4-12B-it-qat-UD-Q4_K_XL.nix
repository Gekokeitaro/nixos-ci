{llama-server}: {
  "Unsloth Gemma4 12B QAT Q4_K_XL" = {
    name = "Unsloth Gemma4 12B QAT Q4_K_XL";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/gemma-4-12B-it-qat-UD-Q4_K_XL.gguf
      --model-draft /models/mtp-gemma-4-12B-it.gguf
      --spec-type draft-mtp
      --spec-draft-n-max 6
      --spec-draft-n-min 1
      --n-gpu-layers 99
      --ctx-size 65536
      --threads 1
      --parallel 1
      --flash-attn on
      --jinja
      --no-mmproj
      --no-warmup
    '';
    ttl = 600;
  };
}
