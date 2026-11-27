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
      --ctx-size 65536
      # Window 2026-11-24, by decision: 64k. Same weights class as the DavidAU 27B, whose 65536
      # peaks at 15507 MiB at load — under the 16 GiB soft ceiling, over the 14336 frame; the
      # session pass at 65536 is owed. Never probe this GGUF's grid above 65536: 229376 killed the
      # container (CEILING=65536 from now on).
      # llama-bench-runner/measurements/swift-1.5-qwen3.8-27b-gsq-rco-iq3_xxs-mtp.md.
      --reasoning-preserve
      --reasoning-format deepseek
      --reasoning-effort medium
      --lora /models/Qwen3.8-27B-pi-lora-F16.gguf
      # Spec 2026-11-24, measured with the LoRA at temp 1.0: ngram-mod 12:32:64 reads 1.487x
      # (code 1.870, json 1.582, prose 1.040, acceptance 0.416, +263 MiB). The embedded MTP point
      # (n-max 3, p-min 0.8) read 1.445x and the combination 1.383x, so no draft is served.
      # llama-bench-runner/measurements/swift-1.5-qwen3.8-27b-gsq-rco-iq3_xxs-mtp.md.
      --spec-type ngram-mod
      --spec-ngram-mod-n-match 12 --spec-ngram-mod-n-min 32 --spec-ngram-mod-n-max 64
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
