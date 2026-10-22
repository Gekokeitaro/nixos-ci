# 300626
# ./llama-bench --delay 2 --progress -m /models/Mellum2-12B-A2.5B-Instruct-MXFP4_MOE.gguf -ngl 99 -t 2 -b 512 -ub 256 -ctk q8_0 -ctv q4_0 -fa 1 -ncmoe 16
{llama-server}: {
  "David AU LFM2.5 24B A2B TBrill NEO IQ3_M" = {
    name = "David AU LFM2.5 24B A2B TBrill NEO IQ3_M";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/LFM2.5-24B-A2B-TBrill-NEO-IQ3_M.gguf
      -ngl 99 -fa 1
      -b 256 -ub 256
      --ctx-size 32768
      --temp 0.7 --top-p 0.95 --min-p 0.05 --top-k 64 --repeat-penalty 1.05
      --cache-ram 256 --ctx-checkpoints 3 --no-mmap
      --parallel 1
      --jinja
    '';
    ttl = 600;
  };
}
