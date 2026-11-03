{ buildPiExtension
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_11
, pnpmConfigHook
}:

buildPiExtension rec {
  pname = "pi-processes";
  version = "2026-11-03";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "42e7d0a72bd60fde74eda4ac3e9ca26b47f52522";
    sha256 = "sha256-ynsGXMka7pfrbYVlWHij6z0AriQIwmBT6yZmNuhNWmE=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit pname version src;
    fetcherVersion = 4;
    hash = "sha256-N4ctXQWhzPhKs+uVuX4pluHK+m+7ikhalK4ExBnphfI=";
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
