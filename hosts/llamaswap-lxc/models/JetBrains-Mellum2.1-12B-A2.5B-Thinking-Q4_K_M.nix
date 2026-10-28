# 300626
# ./llama-bench --delay 2 --progress -m /models/Mellum2-12B-A2.5B-Instruct-MXFP4_MOE.gguf -ngl 99 -t 2 -b 512 -ub 256 -ctk q8_0 -ctv q4_0 -fa 1 -ncmoe 16
{llama-server}: {
  "JetBrains Mellum2.1 12B A2.5B Thinking Q8_0" = {
    name = "JetBrains Mellum2.1 12B A2.5B Thinking Q8_0";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Mellum2.1-12B-A2.5B-Thinking-Q8_0.gguf
      -ngl 99 -fa 1
      --ctx-size 65536
      --temp 0.6 --top-p 0.95 --top-k 20
      --parallel 1
      --jinja
    '';
    ttl = 600;
  };
}
