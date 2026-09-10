{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-10";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "aa75b3353836f7868898e3bd58234d21eaff1463";
    sha256 = "sha256-XXqK6RnalPPxoOkW+RY81xRzOnB2VYfoFP47pGcHzEI=";
  };

  npmDepsHash = "sha256-Bto6gZcATd4R2ilK4fYlYzfiVaToLxR/6uCPSPqTuuI=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
