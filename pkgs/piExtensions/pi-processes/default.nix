{ buildPiExtension
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_10
, pnpmConfigHook
}:

buildPiExtension rec {
  pname = "pi-processes";
  version = "2026-05-19";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "d4e70e6a14b18f15c20b8881159ee4ab6f132806";
    sha256 = "sha256-hyz4g3Itz203kpgDXgPrgZrLmh6mUS7T0HH9pHGAAgo=";
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
