{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-11-25";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "a16a37e597289b22750e71bdd4116093ea609cdd";
    sha256 = "sha256-lBethnb9RX2zNJRYUssCQmbTSIobmKcRgyOqcTFtCw4=";
  };

  npmDepsHash = "sha256-qtYTJJ+BN715N9tzLOOPyAM5wymO0jfbVPi0HtRNkZo=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
