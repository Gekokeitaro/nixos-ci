{llama-server}: {
  "Unsloth Gemma 4 12B QAT UD Q4_K_XL" = {
    name = "Unsloth Gemma 4 12B QAT UD Q4_K_XL";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/gemma-4-12B-it-qat-UD-Q4_K_XL.gguf
      --spec-type draft-mtp
      -md /models/mtp-gemma-4-12B-it-Q8_0.gguf
      -ngl 99 -fa 1
      -b 256 -ub 128 -ctk f16 -ctv q4_0
      --ctx-size 32768
      --temp 1 --top-p 0.95 --top-k 64
      --dry-multiplier 0.8 --dry-base 1.75 --dry-allowed-length 2 --dry-penalty-last-n -1
      --cache-ram 0 --ctx-checkpoints 4
      --parallel 1
      --jinja
    '';
    ttl = 600;
  };
}
