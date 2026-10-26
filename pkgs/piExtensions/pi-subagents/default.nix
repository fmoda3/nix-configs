{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-10-26";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "cb07b1117315b335ec7c71751c6813663cfeff7f";
    sha256 = "sha256-Abcdpb/mNaxORjNn6QEiBR8rh199Y41TYuQR/4dM+6k=";
  };

  npmDepsHash = "sha256-zspaOrko6rPfdi20ycNW3mBCauZLibnvaXnKcirt8KI=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
