{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-10-13";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "9861ad72a11c9af419b39f9b00860708407f7025";
    sha256 = "sha256-9+C1qhUzib1s4Y/SI7ZXiW/cyha86OcCL+L7ugPRBAg=";
  };

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-c7II9Z32rje4RD6sMyAyNUTnKfscoh0A2gBc6ZWfa2U=";
}
