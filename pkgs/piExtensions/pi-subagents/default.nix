{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-10-01";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "0ad173c99bb3e11a4dc6db7a0c6c2f9d2edb295a";
    sha256 = "sha256-EW7sPwwzcganqinISTfqVOEetHKLPDZSBeh2jBbxIFA=";
  };

  npmDepsHash = "sha256-dLLyib2Bgz4bAdslKaiIhqd24eycuiHxpZWVdIpWPYg=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
