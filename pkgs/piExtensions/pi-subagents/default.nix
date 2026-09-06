{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-06";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "df26ebc81920bcaaf848227e42f11c23058ee391";
    sha256 = "sha256-dkmPJRfl3s0w9BKAWOBrhqTeAXm/m1mCR5CzH+1gPHA=";
  };

  npmDepsHash = "sha256-9ELFScZJI4mxupnvvAeUzG1ESBEUdYLOTqeDrLOmmCk=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
