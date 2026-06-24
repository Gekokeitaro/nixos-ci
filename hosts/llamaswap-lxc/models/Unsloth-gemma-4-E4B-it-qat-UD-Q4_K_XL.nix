{llama-server}: {
  "Unsloth Gemma4 E4B QAT Q4_K_XL" = {
    name = "Unsloth Gemma4 E4B QAT Q4_K_XL";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/gemma-4-E4B-it-qat-UD-Q4_K_XL.gguf
      --model-draft /models/mtp-gemma-4-E4B-it.gguf
      --spec-type draft-mtp,ngram-mod
      --spec-draft-n-max 6
      --spec-draft-n-min 4
      --n-gpu-layers 99
      --ctx-size 65536
      --threads 4
      --parallel 1
      --flash-attn off
      --jinja
      --reasoning off
      --no-spec-draft-backend-sampling
      --no-mmproj
      --no-warmup
    '';
    ttl = 600;
  };
}
