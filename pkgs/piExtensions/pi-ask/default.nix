{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-ask";
  version = "2026-05-02";

  src = fetchFromGitHub {
    owner = "eko24ive";
    repo = "pi-ask";
    rev = "924bae28c8ea25624445200c472cd0e842fceb84";
    sha256 = "sha256-Zs/rKvciqlBPLkfvjYar3sSVukHURk9SDM8Lp8yeQAo=";
  };

  prunePaths = [ ".github" ];
}
