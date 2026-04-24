{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-04-23";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "10d4a7e486a7eb91992b05435ab2fe7e3f504ccf";
    sha256 = "sha256-MkCRFuDa/OouSztuNgk+3lnKgWZbQSdL6kfCy4RNCyA=";
  };

  prunePaths = [ ".github" ];
}
