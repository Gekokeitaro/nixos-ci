{llama-server}: {
  "Jackrong Qwopus3.5 9B Coder MTP" = {
    name = "Jackrong Qwopus3.5 9B Coder MTP";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Qwopus3.5-9B-Coder-MTP-Q4_K_M.gguf
      --spec-type draft-mtp
      --spec-draft-n-max 4
      --spec-draft-n-min 2
      --n-gpu-layers 99
      --ctx-size 65536
      --threads 4
      --parallel 1
      --flash-attn on
      --jinja
      --no-warmup
    '';
    ttl = 600;
  };
}
