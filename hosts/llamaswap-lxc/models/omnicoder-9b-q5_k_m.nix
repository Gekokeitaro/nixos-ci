{llama-server}: {
  "OmniCoder-9B Q5_K_M" = {
    name = "OmniCoder-9B Q5_K_M";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/omnicoder-9b-q5_k_m.gguf
      --spec-type ngram-mod,draft-mtp
      --spec-draft-n-max 4
      --spec-draft-n-min 2
      -ngl 99 -t 4
      -b 512 -ub 512
      -ctk q8_0 -ctv q8_0 -fa 1
      --ctx-size 65536
      --parallel 1
      --jinja
      --no-mmap
      --no-warmup
    '';
    ttl = 600;
  };
}
