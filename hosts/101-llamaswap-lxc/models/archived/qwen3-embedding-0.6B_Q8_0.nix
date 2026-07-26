{llama-server}: {
  "Qwen3-Embedding-0.6B-Q8_0" = {
    name = "Qwen3 Embedding 0.6B Q8_0";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Qwen3-Embedding-0.6B-Q8_0.gguf
      --embedding
      --pooling last
      --ctx-size 8192
      --batch-size 512
      --ubatch-size 512
      --threads 1
      --parallel 1
      --fit off
      --no-warmup
    '';
    ttl = 600;
  };
}
