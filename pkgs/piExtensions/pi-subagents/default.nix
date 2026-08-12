{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-12";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "6cab2a2fe43e7a7409891b453a047d8c8fe51e41";
    sha256 = "sha256-zVCHD0nQ6aCJN/U0nvsDDES+UuU3J5U01FMT2AQFywM=";
  };

  npmDepsHash = "sha256-5SlbEYUpIap6ffJT9Q3uw66wM6GAXlPvps9cKMD5t2I=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
