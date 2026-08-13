{ buildPiExtension
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_11
, pnpmConfigHook
}:

buildPiExtension rec {
  pname = "pi-processes";
  version = "2026-08-12";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "550b2e9fe0a5e9ebb77612dfc2f672d4038161b4";
    sha256 = "sha256-UQAtD/wuRUF4fe3ZaXgQ9ZEoxWsWPrpUz865kqYYpfs=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit pname version src;
    fetcherVersion = 4;
    hash = "sha256-vyrLT7MGkwrIVg2HjlogxddSoDgBb9R15ifzRqyjuYI=";
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
