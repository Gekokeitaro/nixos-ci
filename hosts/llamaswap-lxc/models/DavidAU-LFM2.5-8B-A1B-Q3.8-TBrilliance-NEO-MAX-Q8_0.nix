# 300626
# ./llama-bench --delay 2 --progress -m /models/Mellum2-12B-A2.5B-Instruct-MXFP4_MOE.gguf -ngl 99 -t 2 -b 512 -ub 256 -ctk q8_0 -ctv q4_0 -fa 1 -ncmoe 16
{llama-server}: {
  "David AU LFM2.5 8B A1B Q3.8 TBrilliance NEO MAX Q8_0" = {
    name = "David AU LFM2.5 8B A1B Q3.8 TBrilliance NEO MAX Q8_0";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/LFM2.5-8B-A1B-Q3.8-TBrilliance-NEO-MAX-Q8_0.gguf
      -ngl 99 -fa 1
      --ctx-size 32768
      --temp 0.2 --top-k 80 --repeat-penalty 1.05
      --parallel 1
      --jinja
    '';
    ttl = 600;
  };
}
