{llama-server}: {
  "Yuxinlu1 Gemma4 V2 12B Q4_K_M" = {
    name = "Yuxinlu1 Gemma4 V2 12B Q4_K_M";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/gemma4-v2-Q4_K_M.gguf
      --model-draft /models/gemma-4-12B-it-MTP-Q8_0.gguf
      --spec-type draft-mtp
      --spec-draft-n-max 6
      --spec-draft-n-min 4
      --n-gpu-layers 99
      --ctx-size 65536
      --threads 1
      --parallel 1
      --flash-attn on
      --jinja
      --no-spec-draft-backend-sampling
      --no-mmproj
      --no-warmup
    '';
    ttl = 600;
  };
}
