{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-06-26";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "85348a7fcf2c6a9e46ccf4ff3f9d7a9d8a1288c0";
    sha256 = "sha256-mH3qgufjOwJucqQYSAIFi3fWRovYN0zZaSUvYUbZM1I=";
  };

  prunePaths = [ ".github" ];
}
