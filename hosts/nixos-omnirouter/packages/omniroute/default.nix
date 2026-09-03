{ nodejs, lib, stdenv, fetchFromGitHub, fetchPnpmDeps, pnpmConfigHook, pnpmBuildHook, pnpm_11 }:

let
  omnirouteVersion = "3.8.50";
  omnirouteHash = lib.fakeHash;
  omniroutePnpmDepsHash = lib.fakeHash;
  pnpm = pnpm_11;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "omniroute";
  version = omnirouteVersion;

  src = fetchFromGitHub {
    owner = "diegosouzapw";
    repo = "OmniRoute";
    tag = "v${omnirouteVersion}";
    hash = omnirouteHash;
  };

  nativeBuildInputs = [
    nodejs
    pnpmConfigHook
    pnpm
    pnpmBuildHook
  ];

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    inherit pnpm;
    fetcherVersion = 4;
    hash = omniroutePnpmDepsHash;
  };

  pnpmWorkspaces = [ "open-sse" "packages/browser-pool" ];

  buildPhase = ''
    runHook preBuild
    pnpm run build
    runHook postBuild
  '';

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
