{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-10-27";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "2cab20f8af038a82a80c2ad8fa1df7177f26c0db";
    sha256 = "sha256-Gk1iq9MzhqRwEKoaE71TSTBJxO6aPMu95hmzw/jytPE=";
  };

  npmDepsHash = "sha256-jpFrTf4WLn2XKL2/J+bPyQ0d4bKnGoxuFs+ez/MWkAE=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
