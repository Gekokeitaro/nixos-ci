{llama-server}: {
  "David AU LFM2.5 8B-A1B Q3.8 TBrilliance NEO MAX IQ4_XS" = {
    name = "David AU LFM2.5 8B-A1B Q3.8 TBrilliance NEO MAX IQ4_XS";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/LFM2.5-8B-A1B-Q3.8-TBrilliance-NEO-MAX-IQ4_XS.gguf
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
