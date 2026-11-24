{llama-server, modelLib}: {
  "Unsloth Gemma 4 E4B IT QAT UD Q4_K_XL" = {
    name = "Unsloth Gemma 4 E4B IT QAT UD Q4_K_XL";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/gemma-4-E4B-it-qat-UD-Q4_K_XL.gguf
      # Spec 2026-11-24: the tuned draft alone, 1.847x at temp 1 (n-max 2, p-min 0.8). The
      # combination reads 1.684x, and ngram only helps the json class, where it copies the prompt.
      # llama-bench-runner/measurements/gemma-4-e4b-it-qat-ud-q4-k-xl.md.
      --spec-type draft-mtp
      --spec-draft-n-max 2 --spec-draft-p-min 0.8
      --spec-draft-sampling greedy
      -md /models/mtp-gemma-4-E4B-it-Q8_0.gguf
      ${modelLib.deviceArgs}
      -b 256 -ub 128 -ctk f16 -ctv f16
      --ctx-size 65536
      --temp 1 --top-p 0.95 --top-k 64
    '';
    # The six roles, from the shared library, so the parity suites can run on this id. The card's
    # trio (1.0 / 0.95 / 64, web research 2026-11-23) is what the bare id serves and, since
    # 2026-11-24, what every role serves too: Google gives one preset for all use cases, and the
    # library's role geometry is Qwen's.
    filters = modelLib.mkFilters (
      builtins.mapAttrs (_: role: role // {
        temperature = 1.0;
        top_p = 0.95;
        top_k = 64;
        min_p = 0.0;
        presence_penalty = 0.0;
      }) modelLib.profiles.roles
    );
    ttl = 600;
  };
}
