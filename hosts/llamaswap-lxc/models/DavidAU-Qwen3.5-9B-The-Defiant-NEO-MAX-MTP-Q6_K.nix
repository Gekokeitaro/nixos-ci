# 300626
# ./llama-bench --delay 2 --progress -m /models/Mellum2-12B-A2.5B-Instruct-MXFP4_MOE.gguf -ngl 99 -t 2 -b 512 -ub 256 -ctk q8_0 -ctv q4_0 -fa 1 -ncmoe 16
{llama-server}: {
  "David AU Qwen3.5 9B The Defiant NEO MAX MTP Q6_K" = {
    name = "David AU Qwen3.5 9B The Defiant NEO MAX MTP Q6_K";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Qwen3.5-9B-The-Defiant-Fable-Uncnr-Heretic-plusIQ-TOOLS-NEO-MAX-MTP-Q6_K.gguf
      --spec-type draft-mtp
      -ngl 99 -fa 1
      -b 256 -ub 128 -ctk f16 -ctv f16
      --ctx-size 32768
      --dry-multiplier 0.4 --dry-base 1.75 --dry-allowed-length 2 --dry-penalty-last-n 2048
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
          repeat_penalty = 1.1;
        };

        # Instruct — general
        "\${MODEL_ID}:instruct" = {
          temperature = 0.7;
          top_p = 0.8;
          top_k = 20;
          min_p = 0.0;
          presence_penalty = 1.5;
          repeat_penalty = 1.1;
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
      };
    };

    ttl = 600;
  };
}
