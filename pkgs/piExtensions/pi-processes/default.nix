{ stdenvNoCC
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_10
, pnpmConfigHook
}:
stdenvNoCC.mkDerivation rec {
  pname = "pi-processes";
  version = "2026-04-03";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "80e5964d56190d06d52f93b6b7253f03556b281c";
    sha256 = "sha256-2GVuw0QIuZM0gf4XPIj7slljlj7PtNhx5IehdLQ5sNE=";
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
