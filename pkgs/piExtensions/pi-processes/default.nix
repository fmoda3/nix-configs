{ stdenvNoCC
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_10
, pnpmConfigHook
}:
stdenvNoCC.mkDerivation rec {
  pname = "pi-processes";
  version = "2026-03-20";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "f9ae57c6b30004dcbe8204ef857cfdb431471c1e";
    sha256 = "sha256-53uTmXMzg6FAheotvrEY+iyn64sHt8xHl/C6ynSPw2k=";
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
