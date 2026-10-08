{llama-server}: {
  "Bartowski Ling 3.0 tiny Q8_0" = {
    name = "Bartowski Ling 3.0 tiny Q8_0";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Ling-3.0-tiny-Q8_0.gguf
      --spec-type ngram-mod
      -ngl 99 -fa 1
      --ctx-size 131072
      -ctk q8_0 -ctv q8_0
      --parallel 1
      --jinja
    '';
    ttl = 600;
  };
}
