# 300626
# ./llama-bench --delay 2 --progress -m /models/mellum2-claude-Q4_K_M.gguf -ngl 99 -t 8 -b 512 -ub 512 -ctk q8_0 -ctv q4_0 -fa 1 -ncmoe 16
{llama-server}: {
  "Yuxinlu1 Mellum2 12B A2.5B Claude Opus Thinking Q4_K_M" = {
    name = "Yuxinlu1 Mellum2 12B A2.5B Claude Opus Thinking Q4_K_M";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/mellum2-claude-Q4_K_M.gguf
      --spec-type ngram-mod
      -ngl 99 -t 8
      -b 512 -ub 512
      -ctk q8_0 -ctv q4_0 -fa 1
      -ncmoe 16
      --ctx-size 65536
      --parallel 1
      --jinja
      --no-mmap
    '';
    ttl = 600;
  };
}
