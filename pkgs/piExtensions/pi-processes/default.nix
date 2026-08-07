{ buildPiExtension
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_11
, pnpmConfigHook
}:

buildPiExtension rec {
  pname = "pi-processes";
  version = "2026-08-07";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "c7f60f64b377f24f0b89890f66ab50642387ecc0";
    sha256 = "sha256-xfy3ViScjUroeW7gaFgxjrsqcZnwwOIFsvRpl5YEdmk=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit pname version src;
    fetcherVersion = 4;
    hash = "sha256-VJTpexSfro+LgMDB3Ddqgs96cx7Yal5pYRzMyPyGqMs=";
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
