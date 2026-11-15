{llama-server, modelLib}: {
  "Unsloth Gemma 4 E4B IT QAT UD Q4_K_XL" = {
    name = "Unsloth Gemma 4 E4B IT QAT UD Q4_K_XL";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/gemma-4-E4B-it-qat-UD-Q4_K_XL.gguf
      --spec-type ngram-mod,draft-mtp
      -md /models/mtp-gemma-4-E4B-it-Q8_0.gguf
      ${modelLib.deviceArgs}
      -b 256 -ub 128 -ctk f16 -ctv f16
      --ctx-size 65536
      --temp 1 --top-p 0.95 --top-k 64
    '';
    ttl = 600;
  };
}
