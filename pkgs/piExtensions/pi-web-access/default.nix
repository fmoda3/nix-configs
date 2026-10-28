{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-10-28";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "d6bae3bb8423baabfa77ce737db2b6b30035e947";
    sha256 = "sha256-HA6FUZfMkE1OBaDC0NThQ3mzE7Awi9qG0hLesGlEUMQ=";
  };

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-jyIrcH9OmEPV9bn+BGLEccImRFRHd7ZxMSYGuISXg4Y=";
}
