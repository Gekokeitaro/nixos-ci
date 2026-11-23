{llama-server, modelLib}: let
  # Both ids share every flag but the sampling and the speculative ones.
  commonCmd = ''
    ${llama-server} --port ''${PORT}
    --model /models/gemma-4-12B-it-qat-UD-Q4_K_XL.gguf
    ${modelLib.deviceArgs}
    ${modelLib.checkpointArgs}
    -b 256 -ub 128 -ctk f16 -ctv f16
    --ctx-size 32768
  '';

  # The card's preset, 2026-11-23: temp 1.0, top_p 0.95, top_k 64, one preset for everything and
  # no custom chain. Candidate 4 of skills/sampling/references/sampler-candidates.md, triaged
  # against the host's own chain; the served triage is in ai-tests/measurements/gemma-12b.md.
  cardCmd = ''${commonCmd} --temp 1 --top-p 0.95 --top-k 64'';

  # What the entry served until 2026-11-23. The MTP entry keeps it, so the speculative comparison
  # is not mixed with a sampling change.
  hostCmd = ''${commonCmd} --temp .6 --top-p 0.95 --top-k 20
    --samplers "top_k;top_p;min_p;temperature;dry;typ_p;xtc"'';

  commonFilters = modelLib.mkFilters modelLib.profiles.roles;
in {
  "Unsloth Gemma 4 12B QAT UD Q4_K_XL" = {
    name = "Unsloth Gemma 4 12B QAT UD Q4_K_XL";

    cmd = cardCmd;

    filters = commonFilters;
    ttl = 600;
  };

  "Unsloth Gemma 4 12B QAT UD Q4_K_XL MTP" = {
    name = "Unsloth Gemma 4 12B QAT UD Q4_K_XL (MTP)";

    cmd = ''
      ${hostCmd}
      ${modelLib.specArgs.mtp {draft = "/models/mtp-gemma-4-12B-it-Q8_0.gguf";}}
    '';

    filters = commonFilters;
    ttl = 600;
  };
}
