{ lib
, buildNpmPackage
, fetchzip
, nodejs_20
}:

buildNpmPackage rec {
  pname = "sequential-thinking-mcp";
  version = "2025.7.1";

  nodejs = nodejs_20;

  src = fetchzip {
    url = "https://registry.npmjs.org/@modelcontextprotocol/server-sequential-thinking/-/server-sequential-thinking-${version}.tgz";
    hash = "sha256-Iel7ACHE+3aiAQPGD8IIQlU9iR4ofe6ZRsguFuXDeCg=";
  };

  npmDepsHash = "sha256-2EebePCPqgceoPlP4JPq991JbGG+JGXS2+PcxsSvkAI=";

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  dontNpmBuild = true;
  dontNpmInstall = true;

  buildPhase = '''';

  installPhase = ''
    runHook preInstall
    
    mkdir -p $out/lib/node_modules/@modelcontextprotocol/server-sequential-thinking
    cp -r * $out/lib/node_modules/@modelcontextprotocol/server-sequential-thinking/
    
    mkdir -p $out/bin
    makeWrapper ${nodejs_20}/bin/node $out/bin/sequential-thinking-mcp \
      --add-flags "$out/lib/node_modules/@modelcontextprotocol/server-sequential-thinking/dist/index.js"
    
    runHook postInstall
  '';

  meta = {
    description = "MCP server for sequential thinking and problem solving";
    homepage = "https://github.com/modelcontextprotocol/servers/tree/main/src/sequentialthinking";
    license = lib.licenses.mit;
    mainProgram = "mcp-server-sequential-thinking";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
