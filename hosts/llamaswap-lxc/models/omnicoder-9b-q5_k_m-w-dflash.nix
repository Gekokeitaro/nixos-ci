{llama-server}: {
  "OmniCoder-9B Q5_K_M DFlash" = {
    name = "OmniCoder-9B Q5_K_M (DFlash)";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/omnicoder-9b-q5_k_m.gguf
      --spec-type ngram-mod,draft-dflash
      --spec-draft-model /models/qwen35-9b-dflash-Q4_K_M.gguf
      --spec-draft-n-min 1
      --spec-draft-n-max 2
      -ngl 99 -t 4
      -b 1024 -ub 1024
      -ctk q8_0 -ctv q8_0 -fa 1
      --ctx-size 262144
      --parallel 1
      --jinja
      --no-mmap
      --no-warmup
      --fit off
    '';
    ttl = 600;
  };
}
