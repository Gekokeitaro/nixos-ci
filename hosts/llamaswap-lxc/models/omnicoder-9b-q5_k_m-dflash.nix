{llama-server}: {
  "OmniCoder-9B Q5_K_M DFlash" = {
    name = "OmniCoder-9B Q5_K_M DFlash";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/omnicoder-9b-q5_k_m.gguf
      --spec-type ngram-mod,draft-dflash
      --spec-draft-model /models/qwen35-9b-dflash-Q4_K_M.gguf
      --spec-draft-n-max 3
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
