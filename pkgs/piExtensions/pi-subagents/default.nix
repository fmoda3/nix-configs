{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-28";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "4cd43cae8b87baafd85a50e8eaa3f12f02b8760e";
    sha256 = "sha256-3KrOE6SlyJgEy9pVifXwwxuXaIOguXmMC3x0XswLJ3k=";
  };

  npmDepsHash = "sha256-94LUJcViHqKomNQnxxlca15q2dEN74ZUg4sSH3WzhXk=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
