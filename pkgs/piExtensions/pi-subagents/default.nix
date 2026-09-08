{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-08";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "468ea68eae0cb3fd27044cf9bdcce351f2422c61";
    sha256 = "sha256-CSiI61/IJf6WdqxCViFYcAFCe0IX1mHcqmrzqPvST0U=";
  };

  npmDepsHash = "sha256-9ELFScZJI4mxupnvvAeUzG1ESBEUdYLOTqeDrLOmmCk=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
