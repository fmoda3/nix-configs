{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-10-20";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "7927cf2164cdf65788360905047c321410b6d96b";
    sha256 = "sha256-k9rBu/AvLD1gUDsFcNg34Er/ITX29HYtdBykttix55U=";
  };

  npmDepsHash = "sha256-r0LDVvGNSsRlOzoOrBlA2hb+wv+aiNUSp1zNExzrFj8=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
