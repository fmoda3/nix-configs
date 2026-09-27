{ buildPiExtension
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_11
, pnpmConfigHook
}:

buildPiExtension rec {
  pname = "pi-processes";
  version = "2026-09-26";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "510e9bc6e5d01b42e8175c2b664295fe1645fec0";
    sha256 = "sha256-5frt39MhDE5ZfUGPZvWFI5jGKUvErFkqKkjcE72z/50=";
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
