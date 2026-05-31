{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-05-29";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "5de50dc205106013ade0024c18fe700621f1d967";
    sha256 = "sha256-83lZccQ2cq+NmyC0FZZ3Eu5c/wKqqkZLoot4PkQOcDs=";
  };

  prunePaths = [ ".github" ];
}
