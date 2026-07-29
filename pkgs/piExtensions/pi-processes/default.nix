{ buildPiExtension
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_10
, pnpmConfigHook
}:

buildPiExtension rec {
  pname = "pi-processes";
  version = "2026-07-28";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "42d58914e9c22371cb080d55c94661db7f93c267";
    sha256 = "sha256-KR2TJBSvGHk4/C5yo9vTQGa6SJRT5fRRIOArgHqmBLA=";
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
