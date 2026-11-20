# Battery 2026-11-20 (llama.cpp 1.0.0, this GGUF): tg is flat at 21.8-22.5 t/s in every
# `-b`/`-ub` cell, so the lever is prompt processing. `-ub 512` beats `-ub 128` by 47 % on
# pp512 and pp4096 (295/282 against 197/192 at `-b 2048`), and `-b` is flat from 512 up
# (294/295/295), so the served pair stays. Depth costs: at 16k, pp -27 % and tg -15 %
# (19.1 t/s). Threads: `-t 1` wins on both prompt sizes (pp512 348, pp4096 302) with tg
# equal, and the `-t 2` advantage read on `pp512` alone reverses on the pair, so `-t 1`
# stands. Numbers and the full tables, from the workspace root:
# `llama-bench-runner/measurements/qwen3.6-35b-a3b-reap-48-v2.md`.
# Context 2026-11-20: the ceiling is 196608 at load (VmHWM 13665, KV 3840 at 20 MiB per 1k
# tokens) and 229376 misses it by 34 MiB; a 32k session with checkpoints peaks at 14207 MiB,
# 129 MiB inside the frame. Serving 163840 keeps ~1.9 GiB of margin for one grid step. No
# spec path: the GGUF carries no MTP layers (the loader says so), no draft model exists for
# it, and ngram was never measured here.
{llama-server, modelLib}: {
  "Unsloth Qwen3.6 35B A3B REAP 48 v2" = {
    name = "Unsloth Qwen3.6 35B A3B REAP 48 v2";

    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Qwen3.6-35B-A3B-REAP-48-v2.gguf
      ${modelLib.deviceArgs}
      -t 1
      ${modelLib.checkpointArgs}
      -b 2048 -ub 512 -ctk f16 -ctv f16
      --ctx-size 163840
      --reasoning-preserve
      --reasoning-format deepseek
    '';

    # The six factory roles, and nothing inherited: the legacy profiles this file served
    # (`agent`, `thinking`, `coding`, `instruct`) were set from precedent and never swept, so
    # they are gone rather than kept beside the new ones. The bare id therefore carries **no
    # filter** — it runs on llama.cpp's server defaults, which is the same shape Spark serves.
    # Consequence, stated so nobody is surprised: the 45/96 CORE of 2026-11-20 was taken with
    # `default = agent` and is **stale** from this commit on.
    filters = modelLib.mkFilters modelLib.profiles.roles;

    ttl = 600;
  };
}
