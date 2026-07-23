{ buildPiExtension
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_10
, pnpmConfigHook
}:

buildPiExtension rec {
  pname = "pi-processes";
  version = "2026-07-22";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "0c4efd76b527bea632ab66908e5068ae9bf312ce";
    sha256 = "sha256-ARBN1+7I7erhj3kwhkpfa5/TuWwCXVwI32b9hGMl8Ns=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit pname version src;
    fetcherVersion = 3;
    hash = "sha256-5aQmg49vi+5Us56xoBaj+Jug4eVAw970UfegdQuIN4I=";
    pnpm = pnpm_10;
  };

  nativeBuildInputs = [
    nodejs
    pnpmConfigHook
    pnpm_10
  ];

  env.npm_config_manage_package_manager_versions = "false";

  prunePaths = [
    ".github"
    ".changeset"
    ".husky"
  ];
}
