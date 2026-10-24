{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-10-23";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "1a80e24ecb13b291f035379082208404dba5aba5";
    sha256 = "sha256-pMPXkcw7Fr+IXhE9vdaS+XWwRwhPjx35sxMXbXuCMPc=";
  };

  npmDepsHash = "sha256-O+VByGju1YEhiHy1ic+I30YED5wVXSeIgabN4dJnzK0=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
