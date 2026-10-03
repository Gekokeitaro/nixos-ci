{llama-server}: {
  "Unsloth Devstral Small 2 24B Instruct 2512 UD Q4_K_XL" = {
    name = "Unsloth Devstral Small 2 24B Instruct 2512 UD Q4_K_XL";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Devstral-Small-2-24B-Instruct-2512-UD-Q4_K_XL.gguf
      --spec-type ngram-mod
      -ngl 99 -t 8 -fa 1
      --ctx-size 32768
      --parallel 1
      --jinja
    '';
    ttl = 600;
  };
}
