{llama-server}: {
  "David AU Qwen3.5 9B The Defiant Fable Uncnr Heretic NEO MAX MTP Q4_K_M" = {
    name = "David AU Qwen3.5 9B The Defiant Fable Uncnr Heretic NEO MAX MTP Q4_K_M";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Qwen3.5-9B-The-Defiant-Fable-Uncnr-Heretic-NEO-MAX-MTP-Q4_K_M.gguf
      --spec-type draft-mtp, ngram-mod
      -ngl 99 -fa 1
      --ctx-size 65536
      -ctk q8_0 -ctv q4_0
      --parallel 1
      --jinja
    '';
    ttl = 600;
  };
}
