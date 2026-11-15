# 300626
# ./llama-bench --delay 2 --progress -m /models/Mellum2-12B-A2.5B-Instruct-MXFP4_MOE.gguf -ngl 99 -t 2 -b 512 -ub 256 -ctk q8_0 -ctv q4_0 -fa 1 -ncmoe 16
{llama-server, modelLib}: {
  "David AU Qwen3.5 9B The Defiant NEO MAX MTP Q8_0" = {
    name = "David AU Qwen3.5 9B The Defiant NEO MAX MTP Q8_0";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Qwen3.5-9B-The-Defiant-Fable-Uncnr-Heretic-plusIQ-TOOLS-NEO-MAX-MTP-Q8_0.gguf
      ${modelLib.specArgs.mtp {
        nMin = 2;
        nMax = 4;
        pMin = 0.6;
      }}
      ${modelLib.deviceArgs}
      -b 256 -ub 128 -ctk f16 -ctv f16
      --ctx-size 32768
    '';

    filters = modelLib.mkFilters {
      default = modelLib.profiles.thinking // {repeat_penalty = 1.1;};
      instruct = modelLib.profiles.instruct // {repeat_penalty = 1.1;};
      coding = modelLib.profiles.coding;
    };

    ttl = 600;
  };
}
