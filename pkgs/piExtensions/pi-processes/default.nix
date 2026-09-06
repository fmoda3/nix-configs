{ buildPiExtension
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_11
, pnpmConfigHook
}:

buildPiExtension rec {
  pname = "pi-processes";
  version = "2026-09-05";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "f155117d6a0cb644b316dbf99676956400527754";
    sha256 = "sha256-+wtqY6XU70yVqg9Ss1WnwQBkSw2qjFpqh/GfRq3fv/M=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit pname version src;
    fetcherVersion = 4;
    hash = "sha256-WuAbOUrPcv4bN2RHjX5ciyN6w4ZZc19XMHFvLPCVDLk=";
    pnpm = pnpm_11;
  };

  nativeBuildInputs = [
    nodejs
    pnpmConfigHook
    pnpm_11
  ];

  env.npm_config_manage_package_manager_versions = "false";

  prunePaths = [
    ".github"
    ".changeset"
    ".husky"
  ];
}
