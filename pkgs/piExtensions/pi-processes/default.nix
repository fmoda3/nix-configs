{ buildPiExtension
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_10
, pnpmConfigHook
}:

buildPiExtension rec {
  pname = "pi-processes";
  version = "2026-05-07";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "b0f3ef6e6ec8608969fcf613e9a70c6e13b8cb2a";
    sha256 = "sha256-yClsvNBxguw7gw2zzkbYRG4xfZK+swdoQIxXn/zXlPM=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit pname version src;
    fetcherVersion = 3;
    hash = "sha256-YIh2VCTOLiTpR933ljLR/4EVjj4ie46p//pwDOP0hqY=";
    pnpm = pnpm_10;
  };

  nativeBuildInputs = [
    nodejs
    pnpmConfigHook
    pnpm_10
  ];

  env.npm_config_manage_package_manager_versions = "false";

  prunePaths = [
    ".github"
    ".changeset"
    ".husky"
  ];
}
