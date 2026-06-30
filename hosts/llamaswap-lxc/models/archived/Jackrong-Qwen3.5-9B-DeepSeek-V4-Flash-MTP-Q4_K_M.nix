{llama-server}: {
  "Jackrong Qwen3.5 9B DeepSeek V4 Flash MTP" = {
    name = "Jackrong Qwen3.5 9B DeepSeek V4 Flash MTP";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Qwen3.5-9B-DeepSeek-V4-Flash-MTP-Q4_K_M.gguf
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
