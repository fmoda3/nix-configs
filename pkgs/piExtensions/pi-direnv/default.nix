{ stdenvNoCC }:
stdenvNoCC.mkDerivation {
  pname = "pi-direnv";
  version = "0.1.0";

  src = ./.;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp index.ts $out/
    cp package.json $out/

    runHook postInstall
  '';
}
