{ stdenvNoCC
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_10
, pnpmConfigHook
}:
stdenvNoCC.mkDerivation rec {
  pname = "pi-processes";
  version = "0.6.2";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "2a9730bd79cb26757e532e22d07a21e4d6edf73d";
    sha256 = "sha256-nOBgYW50DilBHgbEXnD1BpK4c3+lMGbB1yMKDhGIcq4=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit pname version src;
    fetcherVersion = 3;
    hash = "sha256-DavrG58gpMbVwnrSpdE3d24BK04EM4p+1Wys/hBiQlA=";
    pnpm = pnpm_10;
  };

  nativeBuildInputs = [
    nodejs
    pnpmConfigHook
    pnpm_10
  ];

  env.npm_config_manage_package_manager_versions = "false";

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github $out/.changeset $out/.husky

    runHook postInstall
  '';
}
