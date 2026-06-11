{ buildPiExtension
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_10
, pnpmConfigHook
}:

buildPiExtension rec {
  pname = "pi-processes";
  version = "2026-06-10";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "eb523640a02aa90e2c1f665aba62efa53ed88be1";
    sha256 = "sha256-Yjqomh2SWj75JCqnGSsjcLZy9TVMjgmx2Kb+/GDZfxs=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit pname version src;
    fetcherVersion = 3;
    hash = "sha256-5aQmg49vi+5Us56xoBaj+Jug4eVAw970UfegdQuIN4I=";
    pnpm = pnpm_10;
  };

  nativeBuildInputs = [
    nodejs
    pnpmConfigHook
    pnpm_10
  ];

  env.npm_config_manage_package_manager_versions = "false";

  prunePaths = [
    ".github"
    ".changeset"
    ".husky"
  ];
}
