{pkgs, llama-server}: let
  lib = pkgs.lib;

  # Un modelo por fichero .nix; archived/ es un directorio y no entra.
  isModelFile = name: type:
    type == "regular"
    && name != "default.nix"
    && lib.hasSuffix ".nix" name;

  modelFiles = lib.filterAttrs isModelFile (builtins.readDir ./.);

  modelSets = lib.mapAttrsToList
    (name: _: import (./. + "/${name}") {inherit llama-server;})
    modelFiles;
in
  # Poka-yoke: dos ficheros con el mismo id de modelo rompen la evaluación.
  lib.foldl' lib.unionOfDisjoint {} modelSets
