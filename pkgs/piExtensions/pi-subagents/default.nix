{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-27";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "3bd1892f8bd635788ad0317f3936c3c9cfb317ce";
    sha256 = "sha256-OgSvdyD3NP/3IqwS7ug1IoBFczfcyL8K9r6DSSfVJOY=";
  };

  npmDepsHash = "sha256-94LUJcViHqKomNQnxxlca15q2dEN74ZUg4sSH3WzhXk=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
