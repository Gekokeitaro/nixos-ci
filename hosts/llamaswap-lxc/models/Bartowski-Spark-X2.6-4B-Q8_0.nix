# https://llama-dry-docs.site/view/docs
# Battery: tg64 base 14.91, range 14.52-15.07 (all within 3% of base), peak VRAM 4459-7281 MiB.
# Winner: -b 256 -ub 128 (tg64 15.02, 4651 MiB), which is what the file already used.
{llama-server, modelLib}: {
  "Bartowski Spark X2.6 4B Q8_0" = {
    name = "Bartowski Spark X2.6 4B Q8_0";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Spark-X2.6-4B-Q8_0.gguf
      ${modelLib.deviceArgs}
      ${modelLib.checkpointArgs}
      -b 256 -ub 128 -ctk f16 -ctv f16
      --ctx-size 65536
      --temp .6 --top-p 0.95 --top-k 20
      --samplers "top_k;top_p;min_p;temperature;dry;typ_p;xtc"
    '';

    filters = modelLib.mkFilters (
      {
        instruct = modelLib.profiles.noThink;
      }
      // modelLib.dryVariants {}
    );

    ttl = 600;
  };
}
