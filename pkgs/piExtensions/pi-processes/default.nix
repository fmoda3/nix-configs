{ buildPiExtension
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_11
, pnpmConfigHook
}:

buildPiExtension rec {
  pname = "pi-processes";
  version = "2026-10-04";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "434fa0a860b1fa4fe9fccdc986964d865ef98e47";
    sha256 = "sha256-8SRtvTGcj6ivz4zBwfJCayQAmr1t6rGTUplw9cP5vgg=";
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
