{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-10-12";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "8e812826269624406458531f9231b679547f5a3a";
    sha256 = "sha256-7F43pFcphvdBDznEF7TMNJ9m71Jp9uzQYET5wWnhOkk=";
  };

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-ZIdXbO6fuaJDfiJfJNgVLcrOVR5Wr7mQTzhkxaAe6iY=";
}
