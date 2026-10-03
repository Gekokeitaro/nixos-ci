{llama-server}: {
  "Unsloth Gemma 4 12B QAT UD Q4_K_XL" = {
    name = "Unsloth Gemma 4 12B QAT UD Q4_K_XL";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/gemma-4-12B-it-qat-UD-Q4_K_XL.gguf
      --spec-type ngram-mod,draft-mtp
      -md /models/mtp-gemma-4-12B-it-Q4_0.gguf
      -ngl 99 -t 8 -fa 1
      --ctx-size 49152
      --temp 1 --top-p 0.95 --top-k 64
      --parallel 1
      --jinja
    '';
    ttl = 600;
  };
}
