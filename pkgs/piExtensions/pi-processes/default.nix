{ buildPiExtension
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_11
, pnpmConfigHook
}:

buildPiExtension rec {
  pname = "pi-processes";
  version = "2026-11-02";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "7f2544adf68e656e3aa8e7a1d70a8dd65e9f783f";
    sha256 = "sha256-MCLuhYq58ANJZSs515OGH7RixwbxDG/odZrNxPpsbag=";
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
