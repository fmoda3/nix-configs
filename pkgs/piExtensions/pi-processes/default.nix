{ buildPiExtension
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_11
, pnpmConfigHook
}:

buildPiExtension rec {
  pname = "pi-processes";
  version = "2026-09-12";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "2a7639fc68f8db15217f06d0c07ee1df1318b48d";
    sha256 = "sha256-dnrDE9Nn13lB0giJFhx6pxbJgxMT9zYpZoY4D2USRoE=";
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
