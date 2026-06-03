{llama-server}: {
  "bge-reranker-v2-m3-q8_0" = {
    name = "BGE Reranker V2 M3 Q8_0";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/bge-reranker-v2-m3-q8_0.gguf
      --ctx-size 8192
      --n-gpu-layers 99
      --threads 4
      --reranking
      --no-mmap
      --no-warmup
    '';
    ttl = 300;
  };
}
