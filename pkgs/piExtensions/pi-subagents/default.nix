{ lib
, stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-subagents";
  version = "2026-04-21";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "ecd61a8ac75a8dc5759998ad805d5c56c4f071b5";
    sha256 = "sha256-Chh1RoQMq4TgAsbZWa47FTx8+foWL3bT/EacZCbAhTc=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
