# https://llama-dry-docs.site/view/docs
      #--reasoning-budget 4096 --reasoning-budget-message "I have thought enough. Stop reasoning now and write the final answer using what I know."
{llama-server}: {
  "Bartowski Spark X2.6 4B Q8_0" = {
    name = "Bartowski Spark X2.6 4B Q8_0";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Spark-X2.6-4B-Q8_0.gguf
      -ngl 99 -fa 1
      -b 256 -ub 128 -ctk f16 -ctv f16
      --ctx-size 65536
      --temp .6 --top-p 0.95 --top-k 20 --repeat-penalty 1.1
      --dry-multiplier 0.4 --dry-base 1.75 --dry-allowed-length 3 --dry-penalty-last-n 2048
      --samplers "top_k;top_p;min_p;temperature;dry;typ_p;xtc"
      --parallel 1
      --jinja
    '';
    ttl = 600;
  };
}
