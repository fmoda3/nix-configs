{ stdenvNoCC }:
stdenvNoCC.mkDerivation {
  pname = "pi-status-dashboard";
  version = "0.1.0";

  src = ./.;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/src
    cp index.ts $out/
    cp src/*.ts $out/src/
    cp package.json $out/

    runHook postInstall
  '';
}
