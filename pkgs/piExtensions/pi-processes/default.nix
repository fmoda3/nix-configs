{ stdenvNoCC
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_10
, pnpmConfigHook
}:
stdenvNoCC.mkDerivation rec {
  pname = "pi-processes";
  version = "2026-04-20";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "bf6a71697850f8968926af64571309896952f69c";
    sha256 = "sha256-rgSF2M9vZTERpgTo6fP9JAilclEK1vKhtKOJJgIYcDc=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit pname version src;
    fetcherVersion = 3;
    hash = "sha256-g4qudcq6HC05GOpvBtK+md4CVHZkSDvuqw7rDJHEQSM=";
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
