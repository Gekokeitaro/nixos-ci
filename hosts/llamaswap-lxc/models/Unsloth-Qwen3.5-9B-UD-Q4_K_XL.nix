{llama-server}: {
  "Unsloth Qwen3.5 9B UD Q4_K_XL" = {
    name = "Unsloth Qwen3.5 9B UD Q4_K_XL";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Qwen3.5-9B-UD-Q4_K_XL.gguf
      --spec-type ngram-mod,draft-mtp
      -ngl 99 -fa 1
      --ctx-size 65536
      -ctk q8_0 -ctv q8_0
      --parallel 1
      --jinja
    '';

    filters = {
      setParamsByID = {
        # Thinking — general
        "\${MODEL_ID}" = {
          temperature = 1.0;
          top_p = 0.95;
          top_k = 20;
          min_p = 0.0;
          presence_penalty = 1.5;
          repeat_penalty = 1.0;
        };

        # Thinking — coding
        "\${MODEL_ID}:coding" = {
          temperature = 0.6;
          top_p = 0.95;
          top_k = 20;
          min_p = 0.0;
          presence_penalty = 0.0;
          repeat_penalty = 1.0;
        };

        # Instruct — general
        "\${MODEL_ID}:instruct" = {
          temperature = 0.7;
          top_p = 0.8;
          top_k = 20;
          min_p = 0.0;
          presence_penalty = 1.5;
          repeat_penalty = 1.0;
        };

        # Instruct — reasoning
        "\${MODEL_ID}:instruct-reasoning" = {
          temperature = 1.0;
          top_p = 0.95;
          top_k = 20;
          min_p = 0.0;
          presence_penalty = 1.5;
          repeat_penalty = 1.0;
        };
      };
    };

    ttl = 600;
  };
}
