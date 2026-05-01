{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-05-01";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "702a882626bc8c88717d13663bb9d3ca92ad101f";
    sha256 = "sha256-JyCg0ZUhdORqOb5bXNTMoarNsmBuY77poxEgM7HvE8Q=";
  };

  prunePaths = [ ".github" ];
}
