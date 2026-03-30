{ stdenvNoCC
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_10
, pnpmConfigHook
}:
stdenvNoCC.mkDerivation rec {
  pname = "pi-processes";
  version = "2026-03-30";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "2bdee75d5180c6935a6a04e05858f07f4fa7a94d";
    sha256 = "sha256-DJd3J8zaPV/22sIgjOJob06YP9e3+8ewR6TxEP1E1nA=";
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
