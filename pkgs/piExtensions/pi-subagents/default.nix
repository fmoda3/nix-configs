{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-04-26";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "14749772c8c04f97f1e18323961be495e0b987e1";
    sha256 = "sha256-sBBCYr4QKnWeQ5lEhNQUjk9Xj6Ic5y1T18iRs6qPBwc=";
  };

  prunePaths = [ ".github" ];
}
