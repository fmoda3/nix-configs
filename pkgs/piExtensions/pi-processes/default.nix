{ buildPiExtension
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_11
, pnpmConfigHook
}:

buildPiExtension rec {
  pname = "pi-processes";
  version = "2026-08-05";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "1ba2a4d8849dd43744712f515ef8e8a003bebbc8";
    sha256 = "sha256-VOlf2skBi9xwc9eLDxErmTZuPL+tnuKhZdXV6tfAeQ4=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit pname version src;
    fetcherVersion = 4;
    hash = "sha256-EFUTuok2ji5W0cX7K9DDXRLFemQ6A7GTh9lVM8s0RqQ=";
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
