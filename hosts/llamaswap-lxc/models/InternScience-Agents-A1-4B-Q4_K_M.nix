{llama-server}: {
  "InternScience - Agents A1 4B Q4" = {
    name = "InternScience - Agents A1 4B Q4";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Agents-A1-4B-Q4_K_M.gguf
      --spec-type ngram-mod
      -ngl 99 -fa 1
      --ctx-size 262144
      --parallel 1
      --temp 0.85 --top-p 0.95 --top-k 20
      --presence-penalty 1.1 --repeat-penalty 1.0
      --jinja
    '';
    ttl = 600;
  };
}
