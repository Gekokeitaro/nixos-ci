{llama-server}: {
  "Bartowski Spark X2.6 4B Q6_K_L" = {
    name = "Bartowski Spark X2.6 4B Q6_K_L";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Spark-X2.6-4B-Q6_K_L.gguf
      --spec-type ngram-mod,draft-mtp
      -ngl 99 -fa 1
      -b 256 -ub 128 -ctk f16 -ctv f16
      --ctx-size 65536
      --temp 1 --top-p 0.95 --top-k 0
      --parallel 1
      --jinja
    '';
    ttl = 600;
  };
}
