{llama-server}: {
  "JetBrains Mellum2 12B A2.5B Instruct" = {
    name = "JetBrains Mellum2 12B A2.5B Instruct";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Mellum2-12B-A2.5B-Instruct-MXFP4_MOE.gguf
      --spec-type ngram-mod
      --n-gpu-layers 99
      --n-cpu-moe 4
      --ctx-size 65536
      --batch-size 4096
      --ubatch-size 512
      --threads 4
      --parallel 1
      --flash-attn on
      --jinja
      --fit off
      --no-mmap
      --mlock
      --no-warmup
    '';
    ttl = 600;
  };
}
