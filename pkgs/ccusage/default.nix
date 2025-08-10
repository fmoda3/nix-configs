{ lib
, buildNpmPackage
, fetchzip
, nodejs_20
}:

buildNpmPackage rec {
  pname = "ccusage";
  version = "15.9.2";

  nodejs = nodejs_20;

  src = fetchzip {
    url = "https://registry.npmjs.org/ccusage/-/ccusage-${version}.tgz";
    hash = "sha256-6MwvGPiYQlmhVt7xplo4d+4S6+JjWoer1jP2EK4eGb4=";
  };

  npmDepsHash = "sha256-uUBqMS3+axjsbbwe5TUDm7idSRiP5xrCzbzUBgooDHo=";
  forceEmptyCache = true;

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall
    
    mkdir -p $out/bin $out/lib/node_modules/ccusage
    cp -r . $out/lib/node_modules/ccusage/
    
    # Create symlink for the binary
    ln -s $out/lib/node_modules/ccusage/dist/index.js $out/bin/ccusage
    chmod +x $out/bin/ccusage
    
    runHook postInstall
  '';

  meta = {
    description = "Analyze your Claude Code token usage and costs from local JSONL files";
    homepage = "https://github.com/ryoppippi/ccusage";
    license = lib.licenses.mit;
    mainProgram = "ccusage";
    maintainers = [ ];
  };
}
