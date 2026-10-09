{llama-server}: {
  "XHToken Spark X2.5 4B Q8_0" = {
    name = "XHToken Spark X2.5 4B Q8_0";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Spark-X2.5-4B-Q8_0.gguf
      --spec-type ngram-mod,draft-simple
      -md /models/Spark-X2.5-1.7B-Q4_K_M.gguf
      -ngl 99 -fa 1
      --ctx-size 131072
      --parallel 1
      --jinja
    '';
    ttl = 600;
  };
}
