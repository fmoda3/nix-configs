{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-mcp-adapter";
  version = "2026-05-11";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "e4c6437b3a40ab659e8885b3edd8d2647d1b7ffb";
    sha256 = "sha256-An8T5HCzofCZ0iNDaUPu8NDk+8ndPgAm+owm6F9kmYM=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-X7rOmOkL9dF9qBITaMaA+iAQ4TKY+SM7SywtA84crKs=";
}
