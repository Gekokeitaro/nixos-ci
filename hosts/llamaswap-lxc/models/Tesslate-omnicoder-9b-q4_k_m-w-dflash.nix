{llama-server}: {
  "Tesslab OmniCoder-9B Q4_K_M DFlash" = {
    name = "Tesslab OmniCoder-9B Q4_K_M (DFlash)";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/omnicoder-9b-q4_k_m.gguf
      --spec-type ngram-mod,draft-dflash
      -md /models/qwen35-9b-dflash-Q4_K_M.gguf
      -ngl 99 -fa 1
      --ctx-size 65536
      -ctk q8_0 -ctv q4_0
      --parallel 1
      --jinja
    '';
    ttl = 600;
  };
}
