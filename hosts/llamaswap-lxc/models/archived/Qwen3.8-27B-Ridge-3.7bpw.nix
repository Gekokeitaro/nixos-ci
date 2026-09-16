# 300626
# ./llama-bench --delay 2 --progress -m /models/Mellum2-12B-A2.5B-Instruct-MXFP4_MOE.gguf -ngl 99 -t 2 -b 512 -ub 256 -ctk q8_0 -ctv q4_0 -fa 1 -ncmoe 16
{llama-server}: {
  "Qwen3.8 27B Ridge 3.7bpw" = {
    name = "Qwen3.8 27B Ridge 3.7bpw";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Qwen3.8-27B-Ridge-3.7bpw.gguf
      --spec-type ngram-mod,draft-mtp
      -ngl 99
      -ctk q8_0 -ctv q8_0 -fa 1
      --ctx-size 65536
      --parallel 1
      --jinja
      --no-mmap
    '';
    ttl = 600;
  };
}
