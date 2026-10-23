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
    rev = "4a500d3aba4a6f0b604a1c24ed4c63af741ef84d";
    sha256 = "sha256-qBmkpGxKV7Zc1Za/YVM+SJvigQhyUjHdyRfOGArqW/o=";
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
