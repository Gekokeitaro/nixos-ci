# 300626
# ./llama-bench --delay 2 --progress -m /models/Mellum2-12B-A2.5B-Instruct-MXFP4_MOE.gguf -ngl 99 -t 2 -b 512 -ub 256 -ctk q8_0 -ctv q4_0 -fa 1 -ncmoe 16
# LoRA 2026-11-23: /models/Qwen3.8-27B-pi-lora-F16.gguf (sha256 a64f9184…d7b67, 318 MB,
# FFN-only, architecture qwen35) applied at scale 1.0. Scale 0 through POST /lora-adapters is the
# adapter-free arm, no redeploy: skills/model-files/references/lora-adapters.md.
{llama-server, modelLib}: {
  "David AU Qwen3.8 27B TBrill 50X RI GSQ RCO IQ3_XXS mtp" = {
    name = "David AU Qwen3.8 27B TBrill 50X RI GSQ RCO IQ3_XXS mtp";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Qwen3.8-27B-Turbo-Brilliance-50X-RI-GSQ-RCO-IQ3_XXS-mtp.gguf
      ${modelLib.specArgs.mtp {
        nMin = 2;
        nMax = 8;
        pMin = 0.6;
      }}
      ${modelLib.deviceArgs}
      ${modelLib.checkpointArgs}
      -b 256 -ub 128 -ctk f16 -ctv f16
      --ctx-size 32768
      --temp 0.7 --top-k 64 --min-p 0.05 --top-p 0.95 --repeat-penalty 1.05
      --lora /models/Qwen3.8-27B-pi-lora-F16.gguf
    '';
    # The six roles from the library, so the parity suites can run on this id; the bare id keeps
    # the DavidAU tester settings in `cmd` (temp .5-1, top_k 64, min_p .05, top_p .95) and the
    # card's tool-calling range (.6-.7). Research: Qwen3.8 card 2026-11-23.
    filters = modelLib.mkFilters modelLib.profiles.roles;
    ttl = 600;
  };
}
