{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-26";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "d3464c528d5dce984ce729afc563571d9cd9c877";
    sha256 = "sha256-3z2vWTOSiU/Wb/snK2NU8iA2Zmjw1Sch+0Me7WFDasM=";
  };

  npmDepsHash = "sha256-iphThPMza97zUMs+d2hWuPYrfYUBX+Dwhp8StgHcx/g=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
