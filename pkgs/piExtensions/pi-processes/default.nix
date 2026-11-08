{ buildPiExtension
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_11
, pnpmConfigHook
}:

buildPiExtension rec {
  pname = "pi-processes";
  version = "2026-11-07";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "cce6ad98e11ea7ef0595d91521599fc92eecddfc";
    sha256 = "sha256-2yQJPog525Aa/Y0VVDeJGhAMLBv8ysZmaamMGeAyzmk=";
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
