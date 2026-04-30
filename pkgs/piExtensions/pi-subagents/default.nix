{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-04-30";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "9e0a8a1388478a162ce8026759649c4d430385ff";
    sha256 = "sha256-OF/sKoILlsj1aDxCHwdnpF2x1cU5/4o1Nf4vR2tzrg4=";
  };

  prunePaths = [ ".github" ];
}
