{ lib
, pkgs
, stdenv
, buildNpmPackage
, fetchFromGitHub
, fetchNpmDeps
, npmHooks
, nodejs_22
}:

let
  version = "4.65.0";
  src = fetchFromGitHub {
    owner = "homebridge";
    repo = "homebridge-config-ui-x";
    rev = "v${version}";
    hash = "sha256-6JGY92oB3Cz9alMssmZCOLuo5G/q62gBRKQ4yiLvh/0=";
  };

  # Deps src and hash for ui subdirectory
  npmDeps_ui = fetchNpmDeps {
    name = "npm-deps-ui";
    src = "${src}/ui";
    hash = "sha256-s8ZuOIvF/aNXlbXprFOpBCmTRofhObl0kC1yBo3BLU4=";
  };
in
buildNpmPackage rec {
  pname = "homebridge-config-ui-x";
  inherit version src;

  nodejs = nodejs_22;

  # Deps hash for the root package
  npmDepsHash = "sha256-GWhg7hWglSP9XinZ3uPtAJXXNvAUcC7Ve3hWmedJMO8=";

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

  # Needed for dependency `@homebridge/node-pty-prebuilt-multiarch`
  # On Darwin systems the build fails with,
  #
  # npm error ../src/unix/pty.cc:413:13: error: use of undeclared identifier 'openpty'
  # npm error   int ret = openpty(&master, &slave, nullptr, NULL, static_cast<winsize*>(&winp));
  #
  # when `node-gyp` tries to build the dep. The below allows `npm` to download the prebuilt binary.
  makeCacheWritable = stdenv.hostPlatform.isDarwin;
  nativeBuildInputs = with pkgs; [
    python3
  ] ++ lib.optionals stdenv.hostPlatform.isDarwin [
    cacert
  ];

  meta = {
    description = "Homebridge Config UI X";
    homepage = "https://github.com/homebridge/homebridge-config-ui-x";
    license = lib.licenses.mit;
    mainProgram = "homebridge-config-ui-x";
    maintainers = with lib.maintainers; [ fmoda3 ];
  };
}
