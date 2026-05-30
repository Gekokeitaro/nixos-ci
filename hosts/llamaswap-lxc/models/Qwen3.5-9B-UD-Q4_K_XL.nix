{llama-server}: {
  "Qwen3.5-9B-UD-Q4_K_XL" = {
    name = "Qwen3.5-9B-UD-Q4_K_XL";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Qwen3.5-9B-UD-Q4_K_XL.gguf
      --spec-type draft-mtp
      --ctx-size 65536
      --batch-size 512
      --ubatch-size 512
      --threads 1
      --n-gpu-layers 999
      --cache-type-k q8_0
      --cache-type-v q4_1
      --temp 0.1
      --top-p 0.9
      --top-k 40
      --repeat-penalty 1.1
      --jinja
      --fit off
      --parallel 1
    '';
    ttl = 600;
  };
}
