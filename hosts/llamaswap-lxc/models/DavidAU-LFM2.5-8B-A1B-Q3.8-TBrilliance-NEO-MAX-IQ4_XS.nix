{llama-server}: {
  "DavidAU LFM2.5 8B A1B Q3.8 TBrilliance NEO MAX IQ4_XS" = {
    name = "DavidAU LFM2.5 8B A1B Q3.8 TBrilliance NEO MAX IQ4_XS";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/LFM2.5-8B-A1B-Q3.8-TBrilliance-NEO-MAX-IQ4_XS.gguf
      --spec-type ngram-mod
      -md /models/Spark-X2.5-1.7B-Q4_K_M.gguf
      -ngl 99 -fa 1
      --ctx-size 131072
      --parallel 1
      --jinja
    '';
    ttl = 600;
  };
}
