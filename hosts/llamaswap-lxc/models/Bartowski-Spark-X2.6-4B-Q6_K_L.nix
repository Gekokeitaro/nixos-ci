# https://llama-dry-docs.site/view/docs
{llama-server}: {
  "Bartowski Spark X2.6 4B Q6_K_L" = {
    name = "Bartowski Spark X2.6 4B Q6_K_L";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Spark-X2.6-4B-Q6_K_L.gguf
      --spec-type ngram-mod
      -ngl 99 -fa 1
      -b 256 -ub 128 -ctk f16 -ctv f16
      --ctx-size 65536
      --temp 1 --top-p 0.95 --top-k 0
      --dry-multiplier 0.8 --dry-base 1.75 --dry-allowed-length 2 --dry-penalty-last-n -1
      --parallel 1
      --jinja
    '';
    ttl = 600;
  };
}
