# https://llama-dry-docs.site/view/docs
# Battery 2026-11-19 (llama.cpp 1.0.0, this GGUF, 12 CPUs, served thread default 8): tg is
# flat at 15.0 t/s in every arm, so the only lever is prompt processing. `-b 256 -ub 128`
# gives pp512 411 and pp4096 295 at the served threads - the best pair measured; `-ub 256`
# reads 400 at one thread and 218 at eight, which is why threads are fixed before comparing
# batch (see skills/llama-bench-battery). KV quantisation rejected: f16/f16 13.01 t/s at
# d16384 against q8_0/q8_0 10.56, -19 %. `-b 4096` with `ub >= 1024` costs 5243-7281 MiB for
# no gain. Peak with this preset 4651 MiB.
# Context 2026-11-19: the ceiling measures 262144 with a margin of 162 MiB (VmHWM 14174, KV
# 9297), the policy cap. Served at 196608: 256k leaves 162 MiB, which is luck rather than
# margin, and 64k of window is the cheaper thing to give up. `--ctx-checkpoints 4` kept.
# Chain 2026-11-19: the explicit `--samplers` list is gone, so llama.cpp's order applies -
# penalties, dry, top_k, top_p, min_p, temperature. The old list ran dry after truncation,
# where it reweights survivors instead of removing tokens, and put temperature before the
# cuts. DRY stays per variant through `dryVariants`.
# No reasoning budget on purpose: a 526 s `ERR_API` on 2026-11-19 looked like an unbounded
# thinking block and was not. The same row on the same cmd answered in 122 s once the
# gateway was healthy, so the server default (-1) stands until something measures a loop.
{llama-server, modelLib}: {
  "Bartowski Spark X2.6 4B Q8_0" = {
    name = "Bartowski Spark X2.6 4B Q8_0";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Spark-X2.6-4B-Q8_0.gguf
      ${modelLib.deviceArgs}
      ${modelLib.checkpointArgs}
      -b 256 -ub 128 -ctk f16 -ctv f16
      --ctx-size 196608
      --temp .6 --top-p 0.95 --top-k 20
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
