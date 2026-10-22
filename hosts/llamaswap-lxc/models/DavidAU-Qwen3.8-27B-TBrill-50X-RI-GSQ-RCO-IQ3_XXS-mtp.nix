# 300626
# ./llama-bench --delay 2 --progress -m /models/Mellum2-12B-A2.5B-Instruct-MXFP4_MOE.gguf -ngl 99 -t 2 -b 512 -ub 256 -ctk q8_0 -ctv q4_0 -fa 1 -ncmoe 16
{llama-server}: {
  "David AU Qwen3.8 27B TBrill 50X RI GSQ RCO IQ3_XXS mtp" = {
    name = "David AU Qwen3.8 27B TBrill 50X RI GSQ RCO IQ3_XXS mtp";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Qwen3.8-27B-Turbo-Brilliance-50X-RI-GSQ-RCO-IQ3_XXS-mtp.gguf
      -ngl 99 -fa 1
      -b 256 -ub 128 -ctk f16 -ctv Q4_0
      --ctx-size 32768
      --temp 0.7 --top-k 64 --min-p 0.05 --top-p 0.95 --repeat-penalty 1.05
      --parallel 1
      --jinja
    '';
    ttl = 600;
  };
}
