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
    rev = "20bb5d09ad0f857116c0db4500b83aae8ec9aa2e";
    sha256 = "sha256-mSDd8EY4rb51sVRkOYyiqKpuLVTicqfh0UnDcXastbU=";
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
