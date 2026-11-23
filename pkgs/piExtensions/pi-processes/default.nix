{ buildPiExtension
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_11
, pnpmConfigHook
}:

buildPiExtension rec {
  pname = "pi-processes";
  version = "2026-11-22";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "290aa5e258008bf6b1f08dab0ee71dbd327cd8b2";
    sha256 = "sha256-7MCY7XKWzqGuDSeC9ZBz2ioqOwlAyOJOrnushOyKJRo=";
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
