
{llama-server}: let
  commonFilters = {
    setParamsByID = {
      # Agent - general
      "\${MODEL_ID}" = {
        temperature = 0.7;
        top_p = 0.8;
        top_k = 20;
        min_p = 0.0;
        presence_penalty = 1.5;
        repeat_penalty = 1.1;
      };

      # Thinking
      "\${MODEL_ID}:thinking" = {
        temperature = 1.0;
        top_p = 0.95;
        top_k = 20;
        min_p = 0.0;
        presence_penalty = 1.5;
        repeat_penalty = 1.1;
      };

      # Coding
      "\${MODEL_ID}:coding" = {
        temperature = 0.6;
        top_p = 0.95;
        top_k = 20;
        min_p = 0.0;
        presence_penalty = 0.0;
        repeat_penalty = 1.0;
      };

      # Instruct - disable thinking
      "\${MODEL_ID}:instruct" = {
        chat_template_kwargs = {
          enable_thinking = false;
        };
      };

      # DRY
      "\${MODEL_ID}:dry" = {
        dry_multiplier = 0.4;
        dry_base = 1.75;
        dry_allowed_length = 3;
        dry_penalty_last_n = 2048;
      };

      # DRY + Budget 4096
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

      # DRY + Budget 6144
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
    -ngl 99 -t 1
    -b 2048 -ub 512 -ctk f16 -ctv f16 -fa 1
    --ctx-size 32768
    --cache-ram 512 --ctx-checkpoints 4
    --parallel 1
    --jinja
    --reasoning-preserve
    --reasoning-format deepseek
  '';

in {
  "Unsloth Qwen3.6 35B A3B REAP 48 v2" = {
    name = "Unsloth Qwen3.6 35B A3B REAP 48 v2";

    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Qwen3.6-35B-A3B-REAP-48-v2.gguf
      ${commonArgs}
    '';

    filters = commonFilters;
    ttl = 600;
  };
}
