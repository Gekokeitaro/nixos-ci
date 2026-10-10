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
      --temp 0.6 --top-p 0.95 --top-k 20
      --parallel 1
      --jinja
      --reasoning off
    '';
    ttl = 600;
  };
}
