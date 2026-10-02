{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-10-02";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "f517481f21a2e24b965e0ef1ee4fb6b49ed2def1";
    sha256 = "sha256-4267yoqea8Pvd8vLRFsJBjJH8nbd0jwft2cddJzg+Cc=";
  };

  npmDepsHash = "sha256-dLLyib2Bgz4bAdslKaiIhqd24eycuiHxpZWVdIpWPYg=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
