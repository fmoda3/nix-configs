{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-30";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "26ca2b64c5e5e4ecd292d6d8c47e17c7b89433be";
    sha256 = "sha256-wZNnkUZ+jLDuhxNrs7UscxnbxAcO/bp3bgVYo8cy284=";
  };

  npmDepsHash = "sha256-YR7GAXzi4mTj1yG0ujpnqZnNaGYutLfpfP51/upVsGA=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
