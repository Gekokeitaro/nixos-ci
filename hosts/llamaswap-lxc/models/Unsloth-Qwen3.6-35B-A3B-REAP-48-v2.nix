{llama-server, modelLib}: let
  commonArgs = ''
    ${modelLib.deviceArgs}
    -t 1
    ${modelLib.checkpointArgs}
    -b 2048 -ub 512 -ctk f16 -ctv f16
    --ctx-size 32768
    --reasoning-preserve
    --reasoning-format deepseek
  '';

  commonFilters = modelLib.mkFilters (
    {
      default = modelLib.profiles.agent;
      thinking = modelLib.profiles.thinking // {repeat_penalty = 1.1;};
      coding = modelLib.profiles.coding;
      instruct = modelLib.profiles.noThink;
    }
    // modelLib.dryVariants {}
  );
in {
  "Unsloth Qwen3.6 35B A3B REAP 48 v2" = {
    name = "Unsloth Qwen3.6 35B A3B REAP 48 v2";

    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Qwen3.6-35B-A3B-REAP-48-v2.gguf
      ${commonArgs}
    '';

    filters = commonFilters;
    ttl = 600;
  };
}
