{ lib
, stdenv
, buildNpmPackage
, fetchFromGitHub
, fetchNpmDeps
, npmHooks
, python3
, cacert
, nodejs_22
,
}:

buildNpmPackage.override { nodejs = nodejs_22; } (finalAttrs: {
  pname = "homebridge-config-ui-x";
  version = "5.27.0";

  src = fetchFromGitHub {
    owner = "homebridge";
    repo = "homebridge-config-ui-x";
    tag = "v${finalAttrs.version}";
    hash = "sha256-45a0QPguxRrxSXVhyoHi59jK5qt3onkdoh2ALnO0LJg=";
  };

  # Deps hash for the root package
  npmDepsHash = "sha256-BA7sEC7exQrq4BBK9J7mF+qkGGp7wjOUIoYk4IyuOTM=";

  # Deps src and hash for ui subdirectory
  npmDeps_ui = fetchNpmDeps {
    name = "npm-deps-ui";
    src = "${finalAttrs.src}/ui";
    hash = "sha256-OAzb1cSc6SxO5xZRY5upx42T0wJzUEW3GkkXBo8sMIg=";
  };

  # Need to also run npm ci in the ui subdirectory
  preBuild = ''
    # Apply upstream package patch before TypeScript compilation.
    npm run prepare

    # Tricky way to run npmConfigHook multiple times
    (
      source ${npmHooks.npmConfigHook}/nix-support/setup-hook
      npmRoot=ui npmDeps=${finalAttrs.npmDeps_ui} makeCacheWritable= npmConfigHook
    )
    # Required to prevent "ng build" from failing due to
    # prompting user for autocompletion
    export CI=true
  '';

  # On darwin, the build failed because openpty() is not declared
  # Uses the prebuild version of @homebridge/node-pty-prebuilt-multiarch instead
  makeCacheWritable = stdenv.hostPlatform.isDarwin;

  # npmFlags = [ "--legacy-peer-deps" ];
  npmInstallFlags = [ "--ignore-scripts" ];

  nativeBuildInputs = [
    python3
  ] ++ lib.optionals stdenv.hostPlatform.isDarwin [ cacert ];

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Configure Homebridge, monitor and backup from a browser";
    homepage = "https://github.com/homebridge/homebridge-config-ui-x";
    license = lib.licenses.mit;
    mainProgram = "homebridge-config-ui-x";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    maintainers = with lib.maintainers; [ fmoda3 ];
  };
})
