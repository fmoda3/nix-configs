{ buildNpmPackage
, fetchFromGitHub
, makeWrapper
, nodejs
, node-gyp
, python3
, pkg-config
}:

buildNpmPackage rec {
  pname = "sudocode";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "sudocode-ai";
    repo = "sudocode";
    rev = "v${version}";
    hash = "sha256-2T5orHTMuOvLxePswYMRWltwcnIX1fo9vzCtflpzv4U=";
  };

  npmDepsHash = "sha256-U48Ji2FXklIsITMtcZTOm357kyEBMsniKqJYSaVwQ5o=";

  # makeWrapper for the binary wrappers;
  # python3/node-gyp/pkg-config for better-sqlite3's native build.
  nativeBuildInputs = [
    makeWrapper
    python3
    node-gyp
    pkg-config
  ];

  postPatch = ''
    # The v0.2.0 root lockfile is missing tarball metadata for the CLI's
    # workspace-local commander dependency. Without resolved/integrity npm
    # tries to query the registry during the sandboxed install instead of
    # using the vendored npm dependency cache.
    substituteInPlace package-lock.json \
      --replace-fail $'    "cli/node_modules/commander": {\n      "version": "13.1.0",\n      "license": "MIT",' \
                     $'    "cli/node_modules/commander": {\n      "version": "13.1.0",\n      "resolved": "https://registry.npmjs.org/commander/-/commander-13.1.0.tgz",\n      "integrity": "sha512-/rFeCpNJQbhSZjGVwO9RFV3xPqbnERS8MmIQzCtD/zl6gpJuV/bMLuN92oG3F7d8oDEHHRrujSXNUr8fpjntKw==",\n      "license": "MIT",'
  '';

  # better-sqlite3 ships prebuilt binaries via prebuild-install, which can't
  # phone home from the nix sandbox. Force a from-source build.
  # The @beads/bd workspace dependency downloads a prebuilt binary in its
  # postinstall script. Nix builds must not fetch during the build, and the
  # package only needs better-sqlite3's native rebuild for the built server.
  npmRebuildFlags = [ "better-sqlite3" ];

  # Replace the default npmInstallPhase (which would `npm pack` a single
  # package). We lay out the built tree and create wrappers ourselves.
  installPhase = ''
    runHook preInstall

    mkdir -p $out/libexec/sudocode $out/bin
    cp -r . $out/libexec/sudocode/

    makeWrapper ${nodejs}/bin/node $out/bin/sudocode \
      --add-flags $out/libexec/sudocode/cli/dist/cli.js

    makeWrapper ${nodejs}/bin/node $out/bin/sdc \
      --add-flags $out/libexec/sudocode/cli/dist/cli.js

    makeWrapper ${nodejs}/bin/node $out/bin/sudocode-mcp \
      --add-flags $out/libexec/sudocode/mcp/dist/index.js

    makeWrapper ${nodejs}/bin/node $out/bin/sudocode-server \
      --add-flags $out/libexec/sudocode/server/dist/cli.js

    makeWrapper ${nodejs}/bin/node $out/bin/sudocode-workflow-mcp \
      --add-flags $out/libexec/sudocode/server/dist/workflow/mcp/index.js

    runHook postInstall
  '';

}
