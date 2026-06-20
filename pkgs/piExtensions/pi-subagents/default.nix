{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-06-20";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "bdd1d0c507dc9214048bf656f5e97aad14e60f60";
    sha256 = "sha256-ClaRJDasuWBtrwMUnseUZPKyG/R5NzQsT/Om3TKIt2w=";
  };

  prunePaths = [ ".github" ];
}
