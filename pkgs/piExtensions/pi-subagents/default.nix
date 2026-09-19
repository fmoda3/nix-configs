{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-19";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "e8714ca7bb096a64eb56035a9a517b309d5e26f5";
    sha256 = "sha256-RlvMClfhgRIz0C0HC6NGPkPRMpxNfAOn1N6L8XcYCVw=";
  };

  npmDepsHash = "sha256-K9gDFwFEoXO8ekGOaSoq8OQ2CEVjX8kwOtY7PEdDWnw=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
