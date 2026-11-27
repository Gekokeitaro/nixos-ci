{llama-server, modelLib}: let
  # Both ids share every flag but the speculative ones, and both serve the card's sampling.
  commonCmd = ''
    ${llama-server} --port ''${PORT}
    --model /models/gemma-4-12B-it-qat-UD-Q4_K_XL.gguf
    ${modelLib.deviceArgs}
    ${modelLib.checkpointArgs}
    -b 256 -ub 128 -ctk f16 -ctv f16
    # Window 2026-11-24, measured at load with the speculative stack this file serves: 262144
    # peaks at 12879 MiB (bare 11885), margin 1457 MiB under the 14336 allowance, and the 32k
    # session pass peaks at 10529 MiB with both families drafting. The full-fill pass at 262144
    # is owed, and the margin is what it is measured for: checkpoints grow in a session.
    # llama-bench-runner/measurements/gemma-4-12b-it-qat-ud-q4-k-xl.md.
    --ctx-size 262144
  '';

  # The card's preset, 2026-11-23: temp 1.0, top_p 0.95, top_k 64, one preset for everything and
  # no custom chain. Web research in skills/sampling/references/per-family.md; the served triage is
  # in ai-tests/measurements/gemma-12b.md.
  cardCmd = ''${commonCmd} --temp 1 --top-p 0.95 --top-k 64'';

  # The family's verified truncation applies to every role — top_p 0.95, top_k 64, min_p 0,
  # presence 0, from Google's card (four independent sources). The per-role temperature stays the
  # library's, which comes from the per-task evidence (code 0.0-0.2, reasoning 0.3-0.5): the card's
  # "one preset for all use cases" is read for truncation, not to flatten the task axis. Measuring
  # the implementer at 0.6 against 1.0 is a later question.
  gemmaRoles = builtins.mapAttrs (_: role: role // {
    top_p = 0.95;
    top_k = 64;
    min_p = 0.0;
    presence_penalty = 0.0;
  }) modelLib.profiles.roles;

  commonFilters = modelLib.mkFilters gemmaRoles;
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
      --spec-draft-sampling greedy
      -md /models/mtp-gemma-4-12B-it-Q8_0.gguf
      --spec-ngram-mod-n-match 12 --spec-ngram-mod-n-min 32 --spec-ngram-mod-n-max 64
    '';

    filters = commonFilters;
    ttl = 600;
  };
}
