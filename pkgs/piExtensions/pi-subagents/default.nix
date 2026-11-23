{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-11-22";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "f8248a7d0851df3dec8313764bd0be89d261003d";
    sha256 = "sha256-I8vK89gZ2o6nTL3N0vvE2/BHJVGJMS4m/VspBlsGYvE=";
  };

  npmDepsHash = "sha256-qtYTJJ+BN715N9tzLOOPyAM5wymO0jfbVPi0HtRNkZo=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
