{ buildPiExtension
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_11
, pnpmConfigHook
}:

buildPiExtension rec {
  pname = "pi-processes";
  version = "2026-08-11";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "b8f067a943ca976cdfed44822c5737bde40c033b";
    sha256 = "sha256-kuEzmlAs0I3MH4k215+ceqkhmmDBolJj9mRvXrecbjo=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit pname version src;
    fetcherVersion = 4;
    hash = "sha256-mwJu7+wk77A2OotiX4pUl45TTK/J+VF5ZkPF3WLn52c=";
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
