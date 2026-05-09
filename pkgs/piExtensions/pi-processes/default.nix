{ buildPiExtension
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_10
, pnpmConfigHook
}:

buildPiExtension rec {
  pname = "pi-processes";
  version = "2026-05-09";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "6edf4d2b4915b219b91460747ccf434353795b55";
    sha256 = "sha256-3UKbXUuRYSNgV66a6R+CersD1Vucy37hZ06jRUlbtJk=";
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
