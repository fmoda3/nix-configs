{ buildPiExtension
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_11
, pnpmConfigHook
}:

buildPiExtension rec {
  pname = "pi-processes";
  version = "2026-08-26";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "ca86d4fe3f9be221b19d677bc8f04b23c4ad5268";
    sha256 = "sha256-tCKzVmYuyrCgR6w6eTtQwmbDmXk2NZk+l94UNh9vIRQ=";
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
