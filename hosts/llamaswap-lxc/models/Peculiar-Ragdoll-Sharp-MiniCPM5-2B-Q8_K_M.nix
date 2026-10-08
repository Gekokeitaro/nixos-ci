{llama-server}: {
  "Peculiar Ragdoll Sharp MiniCPM5 2B Q8_K_M" = {
    name = "Peculiar Ragdoll Sharp MiniCPM5 2B Q8_K_M";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Sharp-MiniCPM5-2B-Q8_K_M.gguf
      --spec-type ngram-mod
      -ngl 99 -fa 1
      --ctx-size 131072
      --parallel 1
      --jinja
    '';
    ttl = 600;
  };
}
