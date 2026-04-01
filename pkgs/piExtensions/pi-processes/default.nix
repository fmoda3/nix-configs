{ stdenvNoCC
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_10
, pnpmConfigHook
}:
stdenvNoCC.mkDerivation rec {
  pname = "pi-processes";
  version = "2026-04-01";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "90f1850393e7605e0372faa40f4a8bac2518c2d9";
    sha256 = "sha256-I+42U+u+JXKgdjcrA5f78Fnr+WI0e/2OJM6Rp1OJsGQ=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit pname version src;
    fetcherVersion = 3;
    hash = "sha256-LpnB1vMdhV4qRLI82YzX0KJULpcoG/QtG9XAXN32yBA=";
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
