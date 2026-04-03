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
    rev = "36fd5c6a7ee991c3e6aa3ed550f5e8fb929412c6";
    sha256 = "sha256-anRP8bClOUv/wPMQe/HcRI1orzUmBErF5u8J/qC95b8=";
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
