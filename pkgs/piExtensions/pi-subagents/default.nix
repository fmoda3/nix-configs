{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-23";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "d2ee3dcb90a6521eeca8209b4c489063bbe61636";
    sha256 = "sha256-yPAnS2WKHNM+Cy5fuLTbtXc/8RzuO1qoZGIWaYWwAMg=";
  };

  npmDepsHash = "sha256-49BUnIE/jK1wnBYEAOsyCvMb6h82uNiJMnY7xTQRUdc=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
