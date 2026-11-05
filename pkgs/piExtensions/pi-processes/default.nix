{ buildPiExtension
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_11
, pnpmConfigHook
}:

buildPiExtension rec {
  pname = "pi-processes";
  version = "2026-11-04";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "c56ce2bcf04e58ee155bbc7525fa70a3b6ab1939";
    sha256 = "sha256-EcoApoGP5H/gx5kzfja+vWx9403Lc6C2VlwjdIQNNms=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit pname version src;
    fetcherVersion = 4;
    hash = "sha256-gccnnZv8yK3LdkTAVGjMQWX4EJjrv7jFqjJlAOBKI7c=";
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
