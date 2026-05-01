{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-mcp-adapter";
  version = "2026-05-01";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "662595ef00ae5ba19c0e859e32f20a2a7595dbd3";
    sha256 = "sha256-NYry1MxmMlPRksocycyO7FxGTJuVg513BnwdKv72bWU=";
  };

  npmDepsHash = "sha256-6keQh8iBF224CyZ09QfzWNQuEYYL+nybMPAwu81sp50=";
}
