{llama-server}: {
  "Qwen3.6 35B A3B UD IQ3_XXS" = {
    name = "Qwen3.6 35B A3B UD IQ3_XXS";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Qwen3.6-35B-A3B-UD-IQ3_XXS.gguf
      --spec-type ngram-mod,draft-mtp
      --spec-draft-n-min 2
      --spec-draft-n-max 4
      -ngl 99 -t 4
      -b 1024 -ub 1024
      --reasoning-budget 2048
      --ctx-size 65536
      --parallel 1
      --jinja
    '';
    ttl = 600;
  };
}
