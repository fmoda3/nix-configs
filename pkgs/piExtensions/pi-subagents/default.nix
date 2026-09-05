{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-05";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "379a0daa787eb7da740b71888e1d9eac7873f7a4";
    sha256 = "sha256-YFQq2cc0WysWCD4tbdtoDAO/QzxC3vOSMS9qRz1y1X8=";
  };

  npmDepsHash = "sha256-rVMH0m5XkzL6lAXrzkn2ZphkEKkFoGJyz4n3648ekXU=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
