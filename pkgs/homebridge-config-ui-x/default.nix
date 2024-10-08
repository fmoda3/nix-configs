{ lib
, pkgs
, buildNpmPackage
, fetchFromGitHub
, fetchNpmDeps
, npmHooks
, nodejs_20
}:

let
  version = "4.60.1";
  src = fetchFromGitHub {
    owner = "homebridge";
    repo = "homebridge-config-ui-x";
    rev = "v${version}";
    hash = "sha256-vCLXLEaUVSy5KDxyYmLH+BpCshyqSI8uDsdDoHSWARs=";
  };

  # Deps src and hash for ui subdirectory
  npmDeps_ui = fetchNpmDeps {
    name = "npm-deps-ui";
    src = "${src}/ui";
    hash = "sha256-uS1mh1dztWeed/OByAWet8wPQLu2nYJeGbJOOawK8mc=";
  };
in
buildNpmPackage rec {
  pname = "homebridge-config-ui-x";
  inherit version src;

  nodejs = nodejs_20;

  # Deps hash for the root package
  npmDepsHash = "sha256-zOC35DFBGWLW9ICLU5Ijqv5i5Bp191wREGaxy39mpPI=";

  # Need to also run npm ci in the ui subdirectory
  preBuild = ''
    # Tricky way to run npmConfigHook multiple times
    (
      source ${npmHooks.npmConfigHook}/nix-support/setup-hook
      npmRoot=ui npmDeps=${npmDeps_ui} npmConfigHook
    )
    # Required to prevent "ng build" from failing due to
    # prompting user for autocompletion
    export CI=true
  '';

  nativeBuildInputs = with pkgs; [
    python3
  ] ++ lib.optionals stdenv.isDarwin [
    darwin.cctools
  ];

  meta = {
    description = "Homebridge Config UI X";
    homepage = "https://github.com/homebridge/homebridge-config-ui-x";
    license = lib.licenses.mit;
    mainProgram = "homebridge-config-ui-x";
    maintainers = with lib.maintainers; [ fmoda3 ];
  };
}
