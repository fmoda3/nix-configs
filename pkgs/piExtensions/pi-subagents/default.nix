{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-22";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "b9e55fdbb01e7bcf77c709ec24512608b853c3eb";
    sha256 = "sha256-6apIctmHEPgJKWkCQTC84JFstXfQPDeoBRCGV9At3TE=";
  };

  npmDepsHash = "sha256-S6T0Y19PdpEwF3fbohGa7qPTS6tMZ52jCAv8luh436U=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
