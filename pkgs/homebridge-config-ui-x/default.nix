{ lib
, pkgs
, buildNpmPackage
, fetchFromGitHub
, fetchNpmDeps
, npmHooks
}:

let
  version = "4.50.6";
  src = fetchFromGitHub {
    owner = "homebridge";
    repo = "homebridge-config-ui-x";
    rev = "${version}";
    hash = "sha256-7E/Vp6cmaYlu1ixx+RJNbvf38euXKHMd1ZWlCrwc7Mk=";
  };

  # Deps src and hash for ui subdirectory
  npmDeps_ui = fetchNpmDeps {
    name = "npm-deps-ui";
    src = "${src}/ui";
    hash = "sha256-rIRTEcN75WRbrIr0oPAjw47K3blz/WnEaAGybxyjdbU=";
  };
in
buildNpmPackage rec {
  pname = "homebridge-config-ui-x";
  inherit version src;

  # Deps hash for the root package
  npmDepsHash = "sha256-JRQYtfKkG4dfFoT/kCF/218tRpEZ8HpYfQQmbhxswJ0=";

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
