{ buildPiExtension
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_10
, pnpmConfigHook
}:

buildPiExtension rec {
  pname = "pi-processes";
  version = "2026-05-25";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "cd1cd2368d57e53528f8d93027db7d198deac5c2";
    sha256 = "sha256-JIXOlljY0RrPIQpGiUWyAjCsM3WrNcijEwvqvbJpH+0=";
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
