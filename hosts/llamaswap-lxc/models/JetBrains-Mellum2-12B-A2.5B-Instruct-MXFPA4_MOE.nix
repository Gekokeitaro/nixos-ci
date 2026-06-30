# 300626
# ./llama-bench --delay 2 --progress -m /models/Mellum2-12B-A2.5B-Instruct-MXFP4_MOE.gguf -ngl 99 -t 2 -b 512 -ub 256 -ctk q8_0 -ctv q4_0 -fa 1 -ncmoe 16
{llama-server}: {
  "JetBrains Mellum2 12B A2.5B Instruct" = {
    name = "JetBrains Mellum2 12B A2.5B Instruct";
    cmd = ''
      ${llama-server} --port ''${PORT}
      --model /models/Mellum2-12B-A2.5B-Instruct-MXFP4_MOE.gguf
      --spec-type ngram-mod
      -ngl 99 -t 2
      -b 512 -ub 256
      -ctk q8_0 -ctv q4_0 -fa 1
      -ncmoe 16
      --ctx-size 65536
      --parallel 1
      --jinja
      --no-mmap
    '';
    ttl = 600;
  };
}
