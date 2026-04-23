{ stdenvNoCC
, fetchFromGitHub
, fetchPnpmDeps
, nodejs
, pnpm_10
, pnpmConfigHook
}:
stdenvNoCC.mkDerivation rec {
  pname = "pi-processes";
  version = "2026-04-23";

  src = fetchFromGitHub {
    owner = "aliou";
    repo = "pi-processes";
    rev = "45ba428d07163773be06e040016feec5d157863b";
    sha256 = "sha256-L9O65iqx6vG0czX/S7HRXzvTQ8g/XMrvDY6WKUuobcw=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit pname version src;
    fetcherVersion = 3;
    hash = "sha256-r6z22jb6wt0YSeXUzmnBZNqUwxgVok4TJO4XmFkMeMc=";
    pnpm = pnpm_10;
  };

  nativeBuildInputs = [
    nodejs
    pnpmConfigHook
    pnpm_10
  ];

  env.npm_config_manage_package_manager_versions = "false";

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github $out/.changeset $out/.husky

    runHook postInstall
  '';
}
