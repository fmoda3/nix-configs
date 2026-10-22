{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-10-22";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "07fe5a70e63ce59bb4ca9f19d353fd20ec3a710a";
    sha256 = "sha256-Y1vs/iX8nVp2nE/SSFhTxROvLkING91yitBazQOnUTo=";
  };

  npmDepsHash = "sha256-0eDwWHfFmxouY8uf0VURFYn6dWbDnh6x1Hj8AaARCvc=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
