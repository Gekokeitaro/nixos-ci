{llama-server}: {
  "DeepSeek R1 Distill Qwen 14B Q4_K_M" = {
    name = "DeepSeek R1 Distill Qwen 14B Q4_K_M";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/DeepSeek-R1-Distill-Qwen-14B-Q4_K_M.gguf
      --spec-type ngram-mod,draft-simple
      -md /models/DeepSeek-R1-Distill-Qwen-1.5B-UD-Q4_K_XL.gguf
      -ngl 99 -t 4 -fa 1
      --ctx-size 32768
      --parallel 1
      --jinja
    '';
    ttl = 600;
  };
}
