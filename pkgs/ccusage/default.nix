{ lib
, buildNpmPackage
, fetchzip
, nodejs_20
}:

buildNpmPackage rec {
  pname = "ccusage";
  version = "17.0.3";

  nodejs = nodejs_20;

  src = fetchzip {
    url = "https://registry.npmjs.org/ccusage/-/ccusage-${version}.tgz";
    hash = "sha256-T+nJFb9dqq7FcQg4Tuu7tV4dellQoVhGpxgF1oivY5c=";
  };

  npmDepsHash = "sha256-OP/sKNAjbkFaWKmPb8DtoQBcjxXJo48P5achy4vJ/tA=";
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
