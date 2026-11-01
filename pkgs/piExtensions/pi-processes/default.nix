{ buildPiExtension
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_11
, pnpmConfigHook
}:

buildPiExtension rec {
  pname = "pi-processes";
  version = "2026-10-31";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "0fb886ffed5373494331eed24e7e80a90552e1d9";
    sha256 = "sha256-ZNpNXkyn29QIz8bKZ1N/+ALZ3XcSD/8TVnfaIj+Lu7I=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit pname version src;
    fetcherVersion = 4;
    hash = "sha256-aRUzvIzEHm1mLc/1gx1EDyb//Sdn3pjL/JPcok/GspQ=";
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
