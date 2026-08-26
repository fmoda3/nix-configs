{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-26";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "f97a1f82c02678b7080d250979b823df369c6462";
    sha256 = "sha256-Mq1t/sdR39nDGKSxBt75wp+WKOIeKNmykL51COAewi4=";
  };

  npmDepsHash = "sha256-49BUnIE/jK1wnBYEAOsyCvMb6h82uNiJMnY7xTQRUdc=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
