{llama-server}: {
  "Unsloth LFM2.5 8B A1B UD" = {
    name = "Unsloth LFM2.5 8B A1B UD";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/LFM2.5-8B-A1B-UD-Q4_K_XL.gguf
      --spec-type ngram-mod
      -ngl 99 -fa 1
      --ctx-size 65536
      --parallel 1
      --jinja
      --temperature 0.2 --top-k 80 --repeat-penalty 1.05
    '';
    ttl = 600;
  };
}
