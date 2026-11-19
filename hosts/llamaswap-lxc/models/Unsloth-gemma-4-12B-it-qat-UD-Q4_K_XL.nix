{llama-server, modelLib}: let
  # Both ids share every flag but the speculative ones.
  commonCmd = ''
    ${llama-server} --port ''${PORT}
    --model /models/gemma-4-12B-it-qat-UD-Q4_K_XL.gguf
    ${modelLib.deviceArgs}
    ${modelLib.checkpointArgs}
    -b 256 -ub 128 -ctk f16 -ctv f16
    --ctx-size 32768
    --temp .6 --top-p 0.95 --top-k 20
    --samplers "top_k;top_p;min_p;temperature;dry;typ_p;xtc"
  '';

  commonFilters = modelLib.mkFilters {
    instruct = modelLib.profiles.noThink;
  };
in {
  "Unsloth Gemma 4 12B QAT UD Q4_K_XL" = {
    name = "Unsloth Gemma 4 12B QAT UD Q4_K_XL";

    cmd = commonCmd;

    filters = commonFilters;
    ttl = 600;
  };

  "Unsloth Gemma 4 12B QAT UD Q4_K_XL MTP" = {
    name = "Unsloth Gemma 4 12B QAT UD Q4_K_XL (MTP)";

    cmd = ''
      ${commonCmd}
      ${modelLib.specArgs.mtp {draft = "/models/mtp-gemma-4-12B-it-Q8_0.gguf";}}
    '';

    filters = commonFilters;
    ttl = 600;
  };
}
