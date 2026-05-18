{ lib
, buildNpmPackage
, fetchzip
}:

buildNpmPackage (finalAttrs: {
  pname = "ccusage";
  version = "19.0.3";

  src = fetchzip {
    url = "https://registry.npmjs.org/ccusage/-/ccusage-${finalAttrs.version}.tgz";
    hash = "sha256-9nIZhmt9h2pzEtCpKs4SJ+2T6I+w4lFcAnRGeXvbgxk=";
  };

  npmDepsHash = "sha256-1Lvlt9F7hm8dleBiQ84oDl7xLk9a03uYkBRKx35vT2k=";
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
    ln -s $out/lib/node_modules/ccusage/dist/cli.js $out/bin/ccusage
    chmod +x $out/bin/ccusage
    
    runHook postInstall
  '';

  meta = {
    description = "Analyze coding (agent) CLI token usage and costs from local data";
    homepage = "https://github.com/ryoppippi/ccusage";
    license = lib.licenses.mit;
    mainProgram = "ccusage";
    maintainers = [ ];
  };
})
