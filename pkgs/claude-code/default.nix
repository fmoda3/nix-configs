{ lib
, buildNpmPackage
, fetchzip
, procps
, writableTmpDirAsHomeHook
, versionCheckHook
,
}:

buildNpmPackage (finalAttrs: {
  pname = "claude-code";
  version = "2.1.8";

  src = fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${finalAttrs.version}.tgz";
    hash = "sha256-G54aIqGzAUUsCXwWnXVaT5EfZ8AgmG8fIH8JB7e4lD8=";
  };

  npmDepsHash = "sha256-A7oJP4vbJ3st3/CUDesOk9DkOQJWryyA6Jf8/FKFnTc=";

  strictDeps = true;

  postPatch = ''
    cp ${./package-lock.json} package-lock.json

    # Replace hardcoded `/bin/bash` with `/usr/bin/env bash` for Nix compatibility
    # https://github.com/anthropics/claude-code/issues/15195
    substituteInPlace cli.js \
      --replace-warn '#!/bin/bash' '#!/usr/bin/env bash'
  '';

  dontNpmBuild = true;

  env.AUTHORIZED = "1";

  # `claude-code` tries to auto-update by default, this disables that functionality.
  # https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/overview#environment-variables
  # The DEV=true env var causes claude to crash with `TypeError: window.WebSocket is not a constructor`
  postInstall = ''
    wrapProgram $out/bin/claude \
      --set DISABLE_AUTOUPDATER 1 \
      --unset DEV \
      --prefix PATH : ${
        lib.makeBinPath [
          procps # claude-code uses [node-tree-kill](https://github.com/pkrumins/node-tree-kill) which requires procps's pgrep(darwin) or ps(linux)
        ]
      }
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    writableTmpDirAsHomeHook
    versionCheckHook
  ];
  versionCheckKeepEnvironment = [ "HOME" ];

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Agentic coding tool that lives in your terminal, understands your codebase, and helps you code faster";
    homepage = "https://github.com/anthropics/claude-code";
    downloadPage = "https://www.npmjs.com/package/@anthropic-ai/claude-code";
    license = lib.licenses.unfree;
    mainProgram = "claude";
  };
})
