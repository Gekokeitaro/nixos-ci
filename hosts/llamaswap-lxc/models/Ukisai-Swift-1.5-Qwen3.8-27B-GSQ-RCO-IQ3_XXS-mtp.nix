# 300926
# 18GB VRAM: -ctk q4_0 -ctv q4_0 allows ~131K ctx
# --reasoning-effort medium: 91 think tokens vs 106 xhigh, ~+8% throughput
# LoRA 2026-11-23: /models/Qwen3.8-27B-pi-lora-F16.gguf (sha256 a64f9184…d7b67, 318 MB,
# FFN-only, architecture qwen35) applied at scale 1.0. Scale 0 through POST /lora-adapters is the
# adapter-free arm, no redeploy: skills/model-files/references/lora-adapters.md.
{llama-server, modelLib}: {
  "Ukisai Swift 1.5 Qwen3.8 27B GSQ RCO IQ3_XXS mtp" = {
    name = "Ukisai Swift 1.5 Qwen3.8 27B GSQ RCO IQ3_XXS mtp";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Swift-1.5-Qwen3.8-27B-GSQ-RCO-IQ3_XXS-mtp.gguf
      ${modelLib.deviceArgs}
      --cache-ram 0 --ctx-checkpoints 4
      -b 256 -ub 128 -ctk f16 -ctv f16
      --ctx-size 32768
      --reasoning-preserve
      --reasoning-format deepseek
      --reasoning-effort medium
      --lora /models/Qwen3.8-27B-pi-lora-F16.gguf
    '';

    filters = modelLib.mkFilters (
      modelLib.profiles.roles
      // {
        # The bare id keeps the vendor's thinking preset, with presence off, as it served before.
        default = modelLib.profiles.thinking // {presence_penalty = 0.0;};
      }
    );

    ttl = 600;
  };
}
