{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-mcp-adapter";
  version = "2026-04-24";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "720b677d36320e3c2ed1376a89239a66868c8ac9";
    sha256 = "sha256-Vr1wD6ABj9ZNBgBEpxtvRHYbvUTukeqrS05btiQ5SBo=";
  };

  npmDepsHash = "sha256-Muc0bUf3N9R/1qrD9pn8/1WgNf2UqJWkcQ1nJmcjoeE=";
}
