{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-02";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "d640daba28f33effce013149a65b09f9fd65633e";
    sha256 = "sha256-njI+1LpRyYjeOVlBGz91HUbnCd6hPx4twnI8Wn1s8Cs=";
  };

  npmDepsHash = "sha256-qwZ9+36NM7VaekWEcSdKYHGzKbZCKZ8WGYlS0eF2XO8=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
