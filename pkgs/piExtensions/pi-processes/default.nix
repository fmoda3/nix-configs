{ buildPiExtension
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_11
, pnpmConfigHook
}:

buildPiExtension rec {
  pname = "pi-processes";
  version = "2026-08-27";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "16c1080030e5efd175a268e44ce665fb97bcb68f";
    sha256 = "sha256-4/xdLJDrQFQsCJpTELZ2i2LpMe0PglKVT6m7qcVqVZM=";
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
