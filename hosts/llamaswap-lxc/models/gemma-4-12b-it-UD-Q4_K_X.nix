{llama-server}: {
  "Gemma 4 12B UD Q4_K_X" = {
    name = "Gemma 4 12B UD Q4_K_X";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/gemma-4-12b-it-UD-Q4_K_X.gguf
      --spec-type ngram-mod,draft-mtp
      --spec-draft-n-max 4
      --spec-draft-n-min 2
      -ngl 99 -t 8
      -b 512 -ub 512
      -ctk q8_0 -ctv q4_0 -fa 1
      --ctx-size 65536
      --parallel 1
      --flash-attn on
      --jinja
      --no-warmup
    '';
    ttl = 600;
  };
}
