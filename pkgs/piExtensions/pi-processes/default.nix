{ stdenvNoCC
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_10
, pnpmConfigHook
}:
stdenvNoCC.mkDerivation rec {
  pname = "pi-processes";
  version = "2026-04-17";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "973ba9f66d0b34e3de4342baf2b5bd1fbeccf967";
    sha256 = "sha256-kU/hr2rALj546oS3iK9EKCasG7bKWkqQc/pTsjpqkUg=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit pname version src;
    fetcherVersion = 3;
    hash = "sha256-g2NljQy55of+b1o3DpikgnxgFQaej2p3o/q8YC+sXkM=";
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
