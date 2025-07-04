{ lib
, pkgs
, buildNpmPackage
, fetchFromGitHub
, fetchNpmDeps
, npmHooks
}:

buildNpmPackage (finalAttrs: {
  pname = "homebridge-config-ui-x";
  version = "4.78.1";

  src = fetchFromGitHub {
    owner = "homebridge";
    repo = "homebridge-config-ui-x";
    tag = "v${finalAttrs.version}";
    hash = "sha256-DLWCbX53+KCdaKo0lz8erL823ZXITopdRuARiBQzWIA=";
  };

  # Deps hash for the root package
  npmDepsHash = "sha256-fW2hH5W0PCIUWHiZHDgxfpLPxmncJsAepN8N56c8su0=";

  # Need to also run npm ci in the ui subdirectory
  preBuild =
    let
      # Deps src and hash for ui subdirectory
      npmDeps_ui = fetchNpmDeps {
        name = "npm-deps-ui";
        src = "${finalAttrs.src}/ui";
        hash = "sha256-nJE9OJ+sJP9GwEiqj4KO/RbvsQsYgaF3T3AoAK9nGYQ=";
      };
    in
    ''
      # Tricky way to run npmConfigHook multiple times
      (
        source ${npmHooks.npmConfigHook}/nix-support/setup-hook
        npmRoot=ui npmDeps=${npmDeps_ui} makeCacheWritable= npmConfigHook
      )
      # Required to prevent "ng build" from failing due to
      # prompting user for autocompletion
      export CI=true
    '';

  # On darwin, the build failed because openpty() is not declared
  # Uses the prebuild version of @homebridge/node-pty-prebuilt-multiarch instead
  makeCacheWritable = pkgs.stdenv.hostPlatform.isDarwin;

  nativeBuildInputs = with pkgs; [
    python3
    (lib.optional stdenv.hostPlatform.isDarwin cacert)
  ];

  meta = {
    description = "Homebridge Config UI X";
    homepage = "https://github.com/homebridge/homebridge-config-ui-x";
    license = lib.licenses.mit;
    mainProgram = "homebridge-config-ui-x";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    maintainers = with lib.maintainers; [ fmoda3 ];
  };
})
