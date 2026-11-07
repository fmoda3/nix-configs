{ buildPiExtension
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_11
, pnpmConfigHook
}:

buildPiExtension rec {
  pname = "pi-processes";
  version = "2026-11-06";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "bc2f131ae1b9973144d1e9253ba351119e40ce21";
    sha256 = "sha256-NSIQTTe3StKoCYQsMRzm1sN5+EgeL+0UcJ2yuNvSgmw=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit pname version src;
    fetcherVersion = 4;
    hash = "sha256-x6tVUzv8PiWCM6A9Tydq432v2SRK9iBRz6viiTiXsTA=";
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
