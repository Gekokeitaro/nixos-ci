{llama-server}: {
  "Unsloth GPT OSS 20B Q4_K_M" = {
    name = "Unsloth GPT OSS 20B Q4_K_M";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/gpt-oss-20b-Q4_K_M.gguf
      --spec-type ngram-mod
      --ctx-size 32768
      --n-gpu-layers 99
      --threads 2
      --n-cpu-moe 4
      --parallel 1
      --no-warmup
    '';
    ttl = 600;
  };
}
