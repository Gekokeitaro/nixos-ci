{llama-server, modelLib}: let
  # Both ids share every flag but the speculative ones, and both serve the card's sampling.
  commonCmd = ''
    ${llama-server} --port ''${PORT}
    --model /models/gemma-4-12B-it-qat-UD-Q4_K_XL.gguf
    ${modelLib.deviceArgs}
    ${modelLib.checkpointArgs}
    -b 256 -ub 128 -ctk f16 -ctv f16
    --ctx-size 32768
  '';

  # The card's preset, 2026-11-23: temp 1.0, top_p 0.95, top_k 64, one preset for everything and
  # no custom chain. Web research in skills/sampling/references/per-family.md; the served triage is
  # in ai-tests/measurements/gemma-12b.md.
  cardCmd = ''${commonCmd} --temp 1 --top-p 0.95 --top-k 64'';

  commonFilters = modelLib.mkFilters modelLib.profiles.roles;
in {
  "Unsloth Gemma 4 12B QAT UD Q4_K_XL" = {
    name = "Unsloth Gemma 4 12B QAT UD Q4_K_XL";

    cmd = cardCmd;

    filters = commonFilters;
    ttl = 600;
  };

  # The speculative preset, measured 2026-11-24 at the card's sampling. The two-family combination
  # wins: 3.604x global against 2.858x for ngram-mod alone and 2.609x for the tuned MTP draft, with
  # acceptance 0.444 and +855 MiB over the bare model. Evidence:
  # llama-bench-runner/measurements/gemma-4-12b-it-qat-ud-q4-k-xl.md.
  "Unsloth Gemma 4 12B QAT UD Q4_K_XL MTP" = {
    name = "Unsloth Gemma 4 12B QAT UD Q4_K_XL (MTP)";

    cmd = ''
      ${cardCmd}
      --spec-type ngram-mod,draft-mtp
      --spec-draft-n-max 8 --spec-draft-p-min 0.4
      -md /models/mtp-gemma-4-12B-it-Q8_0.gguf
      --spec-ngram-mod-n-match 12 --spec-ngram-mod-n-min 32 --spec-ngram-mod-n-max 64
    '';

    filters = commonFilters;
    ttl = 600;
  };
}
