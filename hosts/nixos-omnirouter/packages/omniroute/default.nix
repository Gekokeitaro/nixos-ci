{ lib, stdenv, fetchFromGitHub, buildNpmPackage, fetchNpmDeps, nodejs }:

let
  omnirouteVersion = "3.8.50";
  omnirouteHash = lib.fakeHash;
  omnirouteNpmDepsHash = lib.fakeHash;
in
buildNpmPackage (finalAttrs: {
  pname = "omniroute";
  version = omnirouteVersion;

  src = fetchFromGitHub {
    owner = "diegosouzapw";
    repo = "OmniRoute";
    tag = "v${omnirouteVersion}";
    hash = omnirouteHash;
  };

  npmDeps = fetchNpmDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 2;
    hash = omnirouteNpmDepsHash;
  };

  npmFlags = [ "--ignore-scripts" ];
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp -r dist/. $out/
    runHook postInstall
  '';

  meta = with lib; {
    description = "Free MIT AI gateway by Diego Souza";
    license = licenses.mit;
    homepage = "https://omniroute.online";
  };
})