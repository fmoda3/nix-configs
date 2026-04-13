{ buildNpmPackage
, fetchFromGitHub
}:
buildNpmPackage {
  pname = "pi-mcp-adapter";
  version = "2026-04-13";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "999c735f2eb6f8c9237ad9b76668a93964d8be5c";
    sha256 = "sha256-41f4kS6At7GQIfStEeQPRIQaFN5oMs6SrgDsNTeHhLE=";
  };

  npmDepsHash = "sha256-9P71EDq++Bmez3QDEbOL+PCtCFI2ajxy345stBOBp8k=";
  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/

    runHook postInstall
  '';
}
