{ buildPiExtension
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_11
, pnpmConfigHook
}:

buildPiExtension rec {
  pname = "pi-processes";
  version = "2026-08-08";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "71472f163769b19c144f6a16d492323c5f04c64e";
    sha256 = "sha256-gW77wZyEUB00/PsoeOoGVNA3XsgviWskC6mJzTg+rsI=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit pname version src;
    fetcherVersion = 4;
    hash = "sha256-TEAOhrJ2iDlH+0c16mN5TbJwk1XVl2ucL2716qbK4s4=";
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
