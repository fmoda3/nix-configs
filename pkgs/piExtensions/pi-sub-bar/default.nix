{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-sub-bar";
  version = "2026-02-13";

  src = fetchFromGitHub {
    owner = "marckrenn";
    repo = "pi-sub";
    rev = "568087f80a360b795a75171741fc93f5f8be114c";
    sha256 = "sha256-BuDAvV7KeK7psSfODwUBTA04b6LkhFwM/AMQpxlvmgk=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r packages/sub-bar/* $out/

    # Vendor monorepo workspace deps needed at runtime.
    mkdir -p $out/node_modules/@marckrenn
    cp -r packages/sub-core $out/node_modules/@marckrenn/pi-sub-core
    cp -r packages/sub-shared $out/node_modules/@marckrenn/pi-sub-shared

    runHook postInstall
  '';
}
