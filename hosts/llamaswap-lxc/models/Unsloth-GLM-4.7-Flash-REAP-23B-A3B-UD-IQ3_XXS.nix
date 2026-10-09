{llama-server}: {
  "Unsloth GLM-4.7 Flash REAP 23B-A3B UD IQ3_XXS" = {
    name = "Unsloth GLM-4.7 Flash REAP 23B-A3B UD IQ3_XXS";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/GLM-4.7-Flash-REAP-23B-A3B-UD-IQ3_XXS.gguf
      --spec-type ngram-mod
      --ngl 99 -fa 1
      --ctx-size 65536
      --parallel 1
      --jinja
      --temperature 0.7 --top-p 1 --repetition-penalty 1.05
    '';
    ttl = 600;
  };
}
