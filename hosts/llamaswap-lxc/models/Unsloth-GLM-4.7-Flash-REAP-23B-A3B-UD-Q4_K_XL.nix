{llama-server}: {
  "Unsloth GLM 4.7 Flash REAP 23B A3B UD Q4_K_XL" = {
    name = "Unsloth GLM 4.7 Flash REAP 23B A3B UD Q4_K_XL";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/GLM-4.7-Flash-REAP-23B-A3B-UD-Q4_K_XL.gguf
      --spec-type ngram-mod
      -ngl 99 -t 8 -fa 1
      --ctx-size 32768
      --parallel 1
      --jinja
    '';
    ttl = 600;
  };
}
