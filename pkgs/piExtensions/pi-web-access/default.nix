{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-10-08";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "1b6aec4be59eb96fe6f4c8ad1691f863633594fc";
    sha256 = "sha256-tiFkqoZeaUdaEPeww/i9Ryc8kkOT3fQ5VmFhdGKmG0A=";
  };

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-QNn8JSPSTpbQ2FM4hyhYUsTPb9qW0Rr0D8DQ8/5r84w=";
}
