{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-22";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "9cc2bfef13577e9a0121ab1b10a142b222e1bea1";
    sha256 = "sha256-n7BdwxonkLKO/BYId7Sje6y9LxV6bk2qcfBAdEuVcD8=";
  };

  npmDepsHash = "sha256-S6T0Y19PdpEwF3fbohGa7qPTS6tMZ52jCAv8luh436U=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
