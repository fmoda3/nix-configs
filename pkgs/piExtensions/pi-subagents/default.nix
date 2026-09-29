{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-28";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "60905d1001805db11f25f72e75346329dadbc821";
    sha256 = "sha256-vXTxbnjg8juFj0xjLyeX9ChzdlFcAWwRlQ7XJX08ezA=";
  };

  npmDepsHash = "sha256-94LUJcViHqKomNQnxxlca15q2dEN74ZUg4sSH3WzhXk=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
