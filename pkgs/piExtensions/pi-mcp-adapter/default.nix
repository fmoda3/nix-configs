{ buildNpmPackage
, fetchFromGitHub
}:
buildNpmPackage {
  pname = "pi-mcp-adapter";
  version = "2026-03-16";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "01ba9a4e86bd16d895db319b913d73754a473acb";
    sha256 = "sha256-E6Kf+OyTN/pF8pKADJO0B1+buAPqNcXnZl9ssZwSP8U=";
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
