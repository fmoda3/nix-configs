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

let
  # Fix broken lockfile: monaco-editor pins dompurify@3.2.7 but the npm override
  # in package.json forces 3.3.3. Update the lockfile to match the override so
  # monaco-editor uses the top-level dompurify@3.3.3 instead of a missing 3.2.7.
  patchLockfile = lockfile: ''
    ${lib.getExe python3} -c "
    import json
    lockfile = '${lockfile}'
    with open(lockfile) as f:
        data = json.load(f)
    me = data['packages']['node_modules/monaco-editor']
    me['dependencies']['dompurify'] = '3.3.3'
    with open(lockfile, 'w') as f:
        json.dump(data, f, indent=2)
        f.write('\n')
    "
  '';
in

buildNpmPackage.override { nodejs = nodejs_22; } (finalAttrs: {
  pname = "homebridge-config-ui-x";
  version = "5.20.0";

  src = fetchFromGitHub {
    owner = "homebridge";
    repo = "homebridge-config-ui-x";
    tag = "v${finalAttrs.version}";
    hash = "sha256-d3y8mPk/+b4MA7h9VpO3nn1DS3C/C2Vu9Yq3+0cDJno=";
  };

  # Deps hash for the root package
  npmDepsHash = "sha256-cIvGrBaRL9njfRd6FkUtpQZhl09ac/c3f61WvqfoMmI=";

  # Deps src and hash for ui subdirectory
  npmDeps_ui = fetchNpmDeps {
    name = "npm-deps-ui";
    src = "${finalAttrs.src}/ui";
    hash = "sha256-9vmrGsdgWCfYmfpBK3C2xeddKycIZr9tu8gEMiLmuSw=";
    preBuild = patchLockfile "package-lock.json";
    nativeBuildInputs = [ python3 ];
  };

  postPatch = patchLockfile "ui/package-lock.json";

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

  npmFlags = [ "--legacy-peer-deps" ];

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
