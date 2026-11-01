{ lib
, stdenv
, buildNpmPackage
, fetchFromGitHub
, fetchNpmDeps
, npmHooks
, python3
, cacert
, autoPatchelfHook
, nodejs_24
,
}:

buildNpmPackage.override { nodejs = nodejs_24; } (finalAttrs: {
  pname = "homebridge-config-ui-x";
  version = "5.30.0";

  src = fetchFromGitHub {
    owner = "homebridge";
    repo = "homebridge-config-ui-x";
    tag = "v${finalAttrs.version}";
    hash = "sha256-HPBhw4qQCwEUxNUsY2d/90flJl6I3OirvprphjbywbE=";
  };

  # Deps hash for the root package
  npmDepsHash = "sha256-RIPN7suxP42ayArAKBgFDC9VKfVGdzS/1NijO+J6uto=";

  # Deps src and hash for ui subdirectory
  npmDeps_ui = fetchNpmDeps {
    name = "npm-deps-ui";
    src = "${finalAttrs.src}/ui";
    hash = "sha256-Agd6ptPYxyFjv/zgNiWE2o2nCX1doYnoeoRyGJGTwIc=";
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
  '' + lib.optionalString stdenv.hostPlatform.isLinux ''
    # @angular/build uses sass-embedded, which spawns a prebuilt dart binary
    # linked against an FHS dynamic loader. Patch it so it runs in the sandbox.
    for dir in ui/node_modules/sass-embedded-linux-{x64,arm64}/dart-sass; do
      if [ -d "$dir" ]; then autoPatchelf "$dir"; fi
    done
  '' + ''
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
  ] ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [ cacert ];

  # autoPatchelf is only invoked manually in preBuild for sass-embedded; leave
  # the installed output (prebuilt node-pty binaries, etc.) untouched.
  dontAutoPatchelf = true;

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
