{ buildPiExtension
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_11
, pnpmConfigHook
}:

buildPiExtension rec {
  pname = "pi-processes";
  version = "2026-11-20";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "a1efe6555e60cb8357c7ed8d82bae6042b07ecc7";
    sha256 = "sha256-YYB8OwfKAfWrlZoih4zGfi8obWLAjcBb0WaRG2XuMgE=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit pname version src;
    fetcherVersion = 4;
    hash = "sha256-/Rmvyap426WxT/qSiSqHLDxvsCL/rFjuv5jIPoHfeQo=";
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
