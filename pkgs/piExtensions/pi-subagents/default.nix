{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-04-27";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "b91c8810785e2574ade9416d3653a5162d103434";
    sha256 = "sha256-cLkZSh/BLCHOtnpPMfqAnMqvzRReUF3nZ+zd6kzAC9M=";
  };

  prunePaths = [ ".github" ];
}
