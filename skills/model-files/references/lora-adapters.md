# LoRA adapters

A LoRA is a small adapter applied on top of a served GGUF: it changes behaviour without touching
the weights. llama.cpp loads it at startup, so it lives in the model's `cmd`, and the same adapter
can serve several derivatives of one base — the loader only checks the architecture.

## The file

`/models/Qwen3.8-27B-pi-lora-F16.gguf` — 318,802,304 B, **F16 GGUF**, trained for the Qwen3.8 27B
family to improve its behaviour under the `pi` harness. On the host since 2026-11-23.

- **sha256** `a64f91844f19e67da500d8628bdf9383aa334e61b7ab687805802e7d272d7b67`
- `general.type = adapter`, `adapter.type = lora`, `adapter.lora.alpha` present.
- The tensors are **FFN only** (`blk.*.ffn_{down,gate,up}.weight.lora_{a,b}`), no attention.

It is **not in Git**: `/models/` is outside every repository, so a measurement that quotes the
adapter must quote the hash above. A GGUF derivative never implies the adapter — same family,
same architecture (`qwen35`), different weights.

## The flags, from this host's build (llama.cpp 1.0.0)

```
--lora FNAME                    path to LoRA adapter (comma-separated for several)
--lora-scaled FNAME:SCALE,...   adapter with a user-defined scale
--lora-init-without-apply       load the adapter without applying it; enable later with
                                POST /lora-adapters
```

## Applying it

Inside the model's `cmd`, after the model and the device flags:

```nix
cmd = ''
  ${llama-server} --port ''${PORT}
  --model /models/<the-27B>.gguf
  ${modelLib.deviceArgs}
  --lora /models/Qwen3.8-27B-pi-lora-F16.gguf
  ...
'';
```

`--lora` applies at **scale 1.0**. Use `--lora-scaled /models/…:0.8` only when a scale is being
chosen, and record the scale next to the measurement.

**One adapter per process.** The entry's client ids (`:planner`, `:implementer`, …) are
request-level filters of the same server, so a LoRA applies to **every role of that entry**. A
role with and a role without the adapter are two entries with two `cmd`s, as with a per-role
spec.

## Measuring it without a redeploy

Applied at startup with `--lora` (scale 1.0), the adapter stays loaded and the endpoint moves its
scale, so the adapter-free arm is one POST away:

```bash
# scale 0 — the adapter-free arm, same process
curl -s -X POST http://<host>:8080/upstream/<model id URL-encoded>/lora-adapters \
  -H 'Content-Type: application/json' -d '[{"id":0,"scale":0.0}]'
# scale 1 — the arm served by the cmd
curl -s -X POST … -d '[{"id":0,"scale":1.0}]'
```

The same path as `SLOTS_URL` in the harness (llama-swap proxies `/upstream/<model>/…`), so a
scale-0 against scale-1 pair can run on one server start. Until that POST is proven through
llama-swap on this host, treat it as a **candidate method**, not a procedure: the fallback is two
entries, one with `--lora` and one without, and a reload between them.

`--lora-init-without-apply` is the same mechanism with the opposite start: the adapter loads at
scale 0 and the cmd does not change behaviour until the POST.

## The Qwen3.8 27B entries this applies to

All three serve GGUFs whose `general.architecture` is `qwen35`, which is the adapter's:

| model id | file | adapter verdict |
|---|---|---|
| `David AU Qwen3.8 27B TBrill 50X RI GSQ RCO IQ3_XXS mtp` | `DavidAU-Qwen3.8-27B-TBrill-50X-RI-GSQ-RCO-IQ3_XXS-mtp.nix` | apply; the reference case |
| `Ukisai Swift 1.5 Qwen3.8 27B GSQ RCO IQ3_XXS mtp` | `Ukisai-Swift-1.5-Qwen3.8-27B-GSQ-RCO-IQ3_XXS-mtp.nix` | apply; same base family |
| `Prism ML Ternary Bonsai 2 27B Q2_0` | `Prism-ML-Ternary-Bonsai-2-27B-Q2_0-prism-fork-required.nix` | architecture matches, but the weights are a ternary fork; quality unverified, so measure before serving |

`/models/Qwen3.8-27B-IQ3_XXS-2.88bpw.gguf` and `…-IQ4_XS-3.84bpw.gguf` are on the host with no
served entry of their own; if one is onboarded it is the same base and takes the adapter too.

## Cost, and what it does not fix

- **Memory:** 318 MB of adapter on top of the weights; it does not touch the KV, so the context
  ceiling is unchanged apart from that.
- **Speed:** a LoRA is applied per matmul and costs generation throughput. Measure it on the
  GGUF: `tg` and `pp` with the adapter and without, same prompt, same GPU state.
- **Quality:** the whole point, and the only part that needs the evaluation. A LoRA changes
  behaviour, so it is a **candidate**, judged like a sampler: CORE or the role suites against the
  model's own baseline, never against another model, and never on a single run.
- **Not a template, not a sampler.** It does not replace the pinned chat template or the role
  chain, and it must never be summed with another knob in the same measurement.

## Adding a new adapter

1. Convert to GGUF outside the model host (`convert_lora_to_gguf.py`), or download one already in
   GGUF.
2. Copy it to `/models/`, record size and `sha256sum`.
3. Check `general.architecture` matches the served GGUF's (`tr -c '[:print:]' '\n' < file | grep '^qwen'`).
4. Add `--lora` to the `cmd` of one entry, deploy, and measure with the adapter at 1.0 against the
   same GGUF at 0.0.
5. If it wins, extend the flag to the other entries of the same base, one measurement each.
