{ lib
, buildNpmPackage
, fetchzip
, writableTmpDirAsHomeHook
, versionCheckHook
,
}:

buildNpmPackage rec {
  pname = "claude-code";
  version = "2.0.26";

  src = fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-4roXnR6y3jFr7uCZFKTFOyahPjnhJuyVFXunQ89flL4=";
  };

  npmDepsHash = "sha256-CxfQyrzK7JUgH1ajpARl90gESD1S1rl88HvqSTcdguA=";

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  dontNpmBuild = true;

  env.AUTHORIZED = "1";

  # `claude-code` tries to auto-update by default, this disables that functionality.
  # https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/overview#environment-variables
  # The DEV=true env var causes claude to crash with `TypeError: window.WebSocket is not a constructor`
  postInstall = ''
    wrapProgram $out/bin/claude \
      --set DISABLE_AUTOUPDATER 1 \
      --unset DEV
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    writableTmpDirAsHomeHook
    versionCheckHook
  ];
  versionCheckKeepEnvironment = [ "HOME" ];
  versionCheckProgramArg = "--version";

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Agentic coding tool that lives in your terminal, understands your codebase, and helps you code faster";
    homepage = "https://github.com/anthropics/claude-code";
    downloadPage = "https://www.npmjs.com/package/@anthropic-ai/claude-code";
    license = lib.licenses.unfree;
    mainProgram = "claude";
  };
}
