{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-mcp-adapter";
  version = "2026-04-24";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "daae745299db28f075f6e43d3b55133e7ff5ce2f";
    sha256 = "sha256-qLdSf6f8mHQ9jOHiDTI/8qzh1MA5doieY7TasKY1i+k=";
  };

  npmDepsHash = "sha256-ml5sC0dUPpZU30tSNi48a0bP5SRUg2FtwR8nYRW4FhU=";
}
