{llama-server}: {
  "InternScience - Agents A1 4B Q4" = {
    name = "InternScience - Agents A1 4B Q4";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Agents-A1-4B-Q4_K_M.gguf
      -ngl 99 -t 4 -fa 1
      --ctx-size 32768
      --parallel 1
      --temp 0.85 --top-p 0.95 --top-k 20
      --presence-penalty 1.1 --repeat-penalty 1.0
      --jinja
      --cache-ram 0
      --override-tensor 'blk\.[0-9]+\.ssm_(alpha|beta|out|conv1d)\.weight=CPU'
    '';
    ttl = 600;
  };
}
