{llama-server}: {
  "Bartowski Ling 3.0 tiny Q8_0" = {
    name = "Bartowski Ling 3.0 tiny Q8_0";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Ling-3.0-tiny-Q8_0.gguf
      --spec-type ngram-mod
      -ngl 99 -t 8 -fa 1
      --ctx-size 32768
      --parallel 1
      --jinja
    '';
    ttl = 600;
  };
}
