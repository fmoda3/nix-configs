{ buildPiExtension
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_10
, pnpmConfigHook
}:

buildPiExtension rec {
  pname = "pi-processes";
  version = "2026-05-20";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "0958ef30d7a1c7872d0fccb9b2bc3acecdff5099";
    sha256 = "sha256-tSlOUojIC6ojlcooLex89i60Hl+JXl6SYtFiM7WQZ58=";
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
