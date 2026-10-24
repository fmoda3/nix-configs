{ buildPiExtension
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_11
, pnpmConfigHook
}:

buildPiExtension rec {
  pname = "pi-processes";
  version = "2026-10-23";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "7f264d4dd58cc1e7df7067f1683e77c36ee4b523";
    sha256 = "sha256-7oFsmNdDzLMxQCS0llW3IxMA5YRLWu9JMpeu2rglG+8=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit pname version src;
    fetcherVersion = 4;
    hash = "sha256-Ejc7fpZJqMvxD/hEQ7HZCAHtgjo4euIi0F3V0WQt0HI=";
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
