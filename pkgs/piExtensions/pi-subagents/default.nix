{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-08-14";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "de92e5033d558901c0502286fa2ec5281831696b";
    sha256 = "sha256-qIJCSZrxJGZSAAg7hd16PnMifbXauZuBAzdmrLulmaw=";
  };

  npmDepsHash = "sha256-VeUptKmEiwuMyhAozpoIx8SACsJMjk7EFNcE8EG8lhU=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
