{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-10-03";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "3bb9b203d1dbbd52c441a7742a71da57d61e6261";
    sha256 = "sha256-3RQe4SXd2ToM20G+nfaj4x48pwtXOZ+a3/mVeHVPxao=";
  };

  npmDepsHash = "sha256-4OQ8aB9FNBfh+k8GB9ajzQgUMdD4nBzAzqIrtQvoizU=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
