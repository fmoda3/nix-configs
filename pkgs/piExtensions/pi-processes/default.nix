{ stdenvNoCC
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_10
, pnpmConfigHook
}:
stdenvNoCC.mkDerivation rec {
  pname = "pi-processes";
  version = "2026-04-18";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "44846ddeac8ade0799b17798fe93acce3c0387e5";
    sha256 = "sha256-tEUcJq//twTtfYy07/vx8lSKLkUeAeMQy3B+PqQhHa8=";
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
