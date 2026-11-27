{ buildPiExtension
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_11
, pnpmConfigHook
}:

buildPiExtension rec {
  pname = "pi-processes";
  version = "2026-11-26";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "27e981ed7ae8b69824776cc2e555c955371dd0fa";
    sha256 = "sha256-yPbafN/0F+XO0o8zLuiCxQSaX39RJJCh7dBivAloVPM=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit pname version src;
    fetcherVersion = 4;
    hash = "sha256-/Rmvyap426WxT/qSiSqHLDxvsCL/rFjuv5jIPoHfeQo=";
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
