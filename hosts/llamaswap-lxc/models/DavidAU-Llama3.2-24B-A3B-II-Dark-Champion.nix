# 300626
# ./llama-bench --delay 2 --progress -m /models/Mellum2-12B-A2.5B-Instruct-MXFP4_MOE.gguf -ngl 99 -t 2 -b 512 -ub 256 -ctk q8_0 -ctv q4_0 -fa 1 -ncmoe 16
{llama-server, modelLib}: {
  "David AU Llama3.2 24B A3B II Dark Champion" = {
    name = "David AU Llama3.2 24B A3B II Dark Champion";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Llama3.2-24B-A3B-II-Dark-Champion-INSTRUCT-Heretic-Abliterated-Uncensored.i1-Q4_K_S.gguf
      ${modelLib.deviceArgs}
      -b 4096 -ub 1024 -ctk q8_0 -ctv q4_0
      --ctx-size 32768
    '';
    ttl = 600;
  };
}
