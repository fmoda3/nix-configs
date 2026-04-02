{ stdenvNoCC
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_10
, pnpmConfigHook
}:
stdenvNoCC.mkDerivation rec {
  pname = "pi-processes";
  version = "2026-04-02";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "60edfad4a0d5f0c260daff26b68c2f75d109d6e4";
    sha256 = "sha256-KHOw8vnAdoFkZfZnaPedOkxP5K6/ht2KdUEa0mqxPdo=";
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
