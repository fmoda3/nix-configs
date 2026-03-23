{ buildNpmPackage
, fetchFromGitHub
}:
buildNpmPackage {
  pname = "pi-mcp-adapter";
  version = "2026-03-23";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "c0919a29d263c2058c302641ddb04769c21be262";
    sha256 = "sha256-HTexm+b+UUbJD4qwIqlNcVPhF/G7/MtBtXa0AdeztbY=";
  };

  npmDepsHash = "sha256-myJ9h/zC/KDddt8NOVvJjjqbnkdEN4ZR+okCR5nu7hM=";
  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/

    runHook postInstall
  '';
}
