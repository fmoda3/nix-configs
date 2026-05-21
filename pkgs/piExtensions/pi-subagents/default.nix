{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-05-20";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "f096c1a9c0b7480014ddbc6b64f9dc972ee878d7";
    sha256 = "sha256-fAiZWDnedWQ8LJnkSZ335fwpWTq1ZrcL0yXai4rkFxw=";
  };

  prunePaths = [ ".github" ];
}
