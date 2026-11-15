# 300626
# No battery recorded for this GGUF.
{llama-server, modelLib}: {
  "David AU LFM2.5 24B A2B TBrill NEO IQ3_M" = {
    name = "David AU LFM2.5 24B A2B TBrill NEO IQ3_M";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/LFM2.5-24B-A2B-TBrill-NEO-IQ3_M.gguf
      ${modelLib.deviceArgs}
      ${modelLib.checkpointArgs}
      -b 256 -ub 256
      --ctx-size 32768
      --temp 0.7 --top-p 0.95 --min-p 0.05 --top-k 64 --repeat-penalty 1.05
    '';
    ttl = 600;
  };
}
