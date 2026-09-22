{llama-server}: {
  "Gemma 4 12B QAT UD Q4_K_XL" = {
    name = "Gemma 4 12B QAT UD Q4_K_XL";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/gemma-4-12B-it-qat-UD-Q4_K_XL.gguf
      --spec-type ngram-mod,draft-mtp
      --spec-draft-model /models/mtp-gemma-4-12B-it-Q4_0.gguf
      --spec-draft-n-max 2
      -ngl 99 -t 8
      -b 512 -ub 512
      -ctk q8_0 -ctv q4_0 -fa 1
      --ctx-size 65536
      --parallel 1
      --flash-attn on
      --jinja
    '';
    ttl = 600;
  };
}
