# https://llama-dry-docs.site/view/docs
# Battery: tg64 base 14.91, range 14.52-15.07 (all within 3% of base), peak VRAM 4459-7281 MiB.
# Winner: -b 256 -ub 128 (tg64 15.02, 4651 MiB), which is what commonArgs already uses.
{llama-server}:
let 
  commonFilters = {
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
    --ctx-size 65536
    --temp .6 --top-p 0.95 --top-k 20 --repeat-penalty 1.1
    --cache-ram 512 --ctx-checkpoints 4
    --parallel 1
    --samplers "top_k;top_p;min_p;temperature;dry;typ_p;xtc"
    --jinja
  '';

in  {
  "Bartowski Spark X2.6 4B Q8_0" = {
    name = "Bartowski Spark X2.6 4B Q8_0";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Spark-X2.6-4B-Q8_0.gguf
      ${commonArgs}
    '';

    filters = commonFilters;
    ttl = 600;
  };
}
