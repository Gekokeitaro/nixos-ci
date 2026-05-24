{
  pkgs,
  lib,
}: let
  llama-cpp = pkgs.llama-cpp.override {rocmSupport = true;};
  llama-server = lib.getExe' llama-cpp "llama-server";
  PORT = "8080";
in {
  healthCheckTimeout = 60;
  models = {
    "some-model" = {
      cmd = "${llama-server} --port ${PORT} -m /var/lib/llama-cpp/models/some-model.gguf -ngl 0 --no-webui";
      aliases = [
        "the-best"
      ];
    };
    "other-model" = {
      proxy = "http://127.0.0.1:5555";
      cmd = "${llama-server} --port 5555 -m /var/lib/llama-cpp/models/other-model.gguf -ngl 0 -c 4096 -np 4 --no-webui";
      concurrencyLimit = 4;
    };
  };
}
