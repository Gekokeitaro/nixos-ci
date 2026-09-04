{llama-server}: {
  "Unsloth Qwen3.5 9B UD" = {
    name = "Unsloth Qwen3.5 9B UD";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Qwen3.5-9B-UD-Q4_K_XL.gguf
      --spec-type draft-mtp
      --spec-draft-n-max 4
      --spec-draft-n-min 2
      --n-gpu-layers 99
      --ctx-size 65536
      --threads 4
      --parallel 1
      --flash-attn on
      --jinja
      --no-warmup
    '';
    ttl = 600;
  };
}
