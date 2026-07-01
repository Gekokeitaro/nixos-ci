# 010726
# ./llama-bench --delay 10 -m /models/gpt-oss-20b-Q4_K_M.gguf -ngl 99 -t 4 -b 512 -ub 512 -ctk q8_0 -ctv q4_0 -fa 1 -ot ".ffn_(up|down)_exps.=CPU"
{llama-server}: {
  "Unsloth GPT OSS 20B Q4_K_M" = {
    name = "Unsloth GPT OSS 20B Q4_K_M";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/gpt-oss-20b-Q4_K_M.gguf
      --spec-type ngram-mod
      --ctx-size 32768
      -ngl 99 -t 4
      -b 512 -ub 512
      -ctk q8_0 -ctv q4_0 -fa 1
      -ot ".ffn_(up|down)_exps.=CPU"
      --parallel 1
      --no-mmap
    '';
    ttl = 600;
  };
}
