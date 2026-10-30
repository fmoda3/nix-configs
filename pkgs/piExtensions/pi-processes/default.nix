{ buildPiExtension
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_11
, pnpmConfigHook
}:

buildPiExtension rec {
  pname = "pi-processes";
  version = "2026-10-30";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "b1e666b7adff5390737f2fb7d9587c505975ddf5";
    sha256 = "sha256-SzFu9cn1aIEWTJ6m139yvNbUScUtaIJrsaLJVvxE1AM=";
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
