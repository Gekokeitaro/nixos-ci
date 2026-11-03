{llama-server}: let
  commonfilters = {
    setParamsByID = {
      "\${MODEL_ID}:instruct" = {
        chat_template_kwargs = {
          enable_thinking = false;
        };
      };
      "\${MODEL_ID}:dry" = {
        dry_multiplier = 0.4;
        dry_base = 1.75;
        dry_allowed_length = 3;
        dry_penalty_last_n = 2048;
      };
      "\${MODEL_ID}:dry-budget-4000-msg" = {
        dry_multiplier = 0.4;
        dry_base = 1.75;
        dry_allowed_length = 3;
        dry_penalty_last_n = 2048;
        reasoning_budget = 4096;
        reasoning_budget_message = "Enough think. Act now. Finish task. No loops.";
      };
      "\${MODEL_ID}:dry-budget-4000-empty-msg" = {
        dry_multiplier = 0.4;
        dry_base = 1.75;
        dry_allowed_length = 3;
        dry_penalty_last_n = 2048;
        reasoning_budget = 4096;
        reasoning_budget_message = "...";
      };
      "\${MODEL_ID}:dry-budget-4000" = {
        dry_multiplier = 0.4;
        dry_base = 1.75;
        dry_allowed_length = 3;
        dry_penalty_last_n = 2048;
        reasoning_budget = 4096;
      };
      "\${MODEL_ID}:dry-budget-6144-msg" = {
        dry_multiplier = 0.4;
        dry_base = 1.75;
        dry_allowed_length = 3;
        dry_penalty_last_n = 2048;
        reasoning_budget = 6144;
        reasoning_budget_message = "Enough think. Act now. Finish task. No loops.";
      };
      "\${MODEL_ID}:dry-budget-6144-empty-msg" = {
        dry_multiplier = 0.4;
        dry_base = 1.75;
        dry_allowed_length = 3;
        dry_penalty_last_n = 2048;
        reasoning_budget = 6144;
        reasoning_budget_message = "...";
      };
      "\${MODEL_ID}:dry-budget-6144" = {
        dry_multiplier = 0.4;
        dry_base = 1.75;
        dry_allowed_length = 3;
        dry_penalty_last_n = 2048;
        reasoning_budget = 6144;
      };
    };
  };

  commonArgs = ''
    -ngl 99 -fa 1
    -b 256 -ub 128 -ctk f16 -ctv f16
    --ctx-size 32768
    --temp .6 --top-p 0.95 --top-k 20 --repeat-penalty 1.1
    --cache-ram 512 --ctx-checkpoints 4
    --parallel 1
    --samplers "top_k;top_p;min_p;temperature;dry;typ_p;xtc"
    --jinja
  '';

in {
  "Unsloth Gemma 4 12B QAT UD Q4_K_XL" = {
    name = "Unsloth Gemma 4 12B QAT UD Q4_K_XL";

    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/gemma-4-12B-it-qat-UD-Q4_K_XL.gguf
      ${commonArgs}
    '';

    filters = commonFilters;
    ttl = 600;
  };

  "Unsloth Gemma 4 12B QAT UD Q4_K_XL MTP" = {
    name = "Unsloth Gemma 4 12B QAT UD Q4_K_XL (MTP)";

    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/gemma-4-12B-it-qat-UD-Q4_K_XL.gguf
      --spec-type draft-mtp
      -md /models/mtp-gemma-4-12B-it-Q8_0.gguf
      ${commonArgs}
    '';

    filters = commonFilters;
    ttl = 600;
  };
}
