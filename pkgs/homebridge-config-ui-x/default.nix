{ lib
, stdenv
, buildNpmPackage
, fetchFromGitHub
, fetchNpmDeps
, npmHooks
, python3
, cacert
,
}:

buildNpmPackage (finalAttrs: {
  pname = "homebridge-config-ui-x";
  version = "5.2.0";

  src = fetchFromGitHub {
    owner = "homebridge";
    repo = "homebridge-config-ui-x";
    tag = "v${finalAttrs.version}";
    hash = "sha256-y2i4bOAA6lHwis1uK3F8GFftd9+f7fNJI6M19W56hs8=";
  };

  # Deps hash for the root package
  npmDepsHash = "sha256-qdCt+vpxFHG9JjKy63PrUQTq5Y9lOaQf9ObU6xIMSO0=";

  # Deps src and hash for ui subdirectory
  npmDeps_ui = fetchNpmDeps {
    name = "npm-deps-ui";
    src = "${finalAttrs.src}/ui";
    hash = "sha256-bAv++Kb8KaB2PotB0lcgm7KTUq5Kli9r7ZjTAxFiYiY=";
  };

  # Need to also run npm ci in the ui subdirectory
  preBuild = ''
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

  nativeBuildInputs = [
    python3
  ] ++ lib.optionals stdenv.hostPlatform.isDarwin [ cacert ];

  meta = {
    description = "Configure Homebridge, monitor and backup from a browser";
    homepage = "https://github.com/homebridge/homebridge-config-ui-x";
    license = lib.licenses.mit;
    mainProgram = "homebridge-config-ui-x";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    maintainers = with lib.maintainers; [ fmoda3 ];
  };
})
