{ lib
, buildNpmPackage
, fetchzip
, nodejs_20
}:

buildNpmPackage rec {
  pname = "ccusage";
  version = "15.9.4";

  nodejs = nodejs_20;

  src = fetchzip {
    url = "https://registry.npmjs.org/ccusage/-/ccusage-${version}.tgz";
    hash = "sha256-J92rq/J/zxV2X85AwRzKFk3ulMjmIV3HsM54n+c76rM=";
  };

  npmDepsHash = "sha256-R/A6Nk/uH07oCM5UnsEWaSxbSYF3r26YsJ4PFf8tIVM=";
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
