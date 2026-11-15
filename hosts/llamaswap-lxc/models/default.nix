{pkgs, llama-server}: let
  lib = pkgs.lib;

  # The shared fragments, imported here and nowhere else: every model file
  # receives them as `modelLib`.
  modelLib = import ./lib;

  # One model per .nix file; archived/ is a directory and does not count.
  isModelFile = name: type:
    type == "regular"
    && name != "default.nix"
    && lib.hasSuffix ".nix" name;

  modelFiles = lib.filterAttrs isModelFile (builtins.readDir ./.);

  modelSets = lib.mapAttrsToList
    (name: _: import (./. + "/${name}") {inherit llama-server modelLib;})
    modelFiles;
in
  # Poka-yoke: two files with the same model id break evaluation.
  lib.foldl' lib.attrsets.unionOfDisjoint {} modelSets
