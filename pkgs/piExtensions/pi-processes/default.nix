{ buildPiExtension
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_11
, pnpmConfigHook
}:

buildPiExtension rec {
  pname = "pi-processes";
  version = "2026-10-25";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "2064e47408fb100e7126059209b5c35b4f97b8c1";
    sha256 = "sha256-z6P4jc6XuHddD63jfyEI3ZJX7FvesPT1f8xrV/OQRrw=";
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
