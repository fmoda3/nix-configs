{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-sub-bar";
  version = "2026-03-15";

  src = fetchFromGitHub {
    owner = "marckrenn";
    repo = "pi-sub";
    rev = "b5f7b287957dfede37134b6ecbe561dfaff5817d";
    sha256 = "sha256-RYn8UAc2s4ji2eWaBgaBFgQV1EpgbbRt7MDo3XYC7qM=";
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
