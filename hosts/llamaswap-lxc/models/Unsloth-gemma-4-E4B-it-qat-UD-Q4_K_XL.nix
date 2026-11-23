{llama-server, modelLib}: {
  "Unsloth Gemma 4 E4B IT QAT UD Q4_K_XL" = {
    name = "Unsloth Gemma 4 E4B IT QAT UD Q4_K_XL";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/gemma-4-E4B-it-qat-UD-Q4_K_XL.gguf
      --spec-type ngram-mod,draft-mtp
      -md /models/mtp-gemma-4-E4B-it-Q8_0.gguf
      ${modelLib.deviceArgs}
      -b 256 -ub 128 -ctk f16 -ctv f16
      --ctx-size 65536
      --temp 1 --top-p 0.95 --top-k 64
    '';
    # The six roles, from the shared library, so the parity suites can run on this id. The card's
    # trio (1.0 / 0.95 / 64, web research 2026-11-23) is what the bare id serves; the roles keep
    # the library's per-role geometry until session 8b tunes them.
    filters = modelLib.mkFilters modelLib.profiles.roles;
    ttl = 600;
  };
}
