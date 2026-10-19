{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-10-18";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "95683a4427e1e4af8de03f1a9ca03ec4c2799b73";
    sha256 = "sha256-RbxkdXI0gIDBimMKzvLVuKHdTm7q6AZCcy3S1fApVG4=";
  };

  npmDepsHash = "sha256-0B6AKixkKpHYr/ncknxi35chpmOd9hcCM9vX4TTAqP0=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
