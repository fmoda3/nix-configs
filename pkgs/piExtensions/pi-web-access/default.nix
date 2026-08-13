{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-08-12";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "6041a073f1804527bfa15d18f84530c68e633d1b";
    sha256 = "sha256-ERN6UNfNMQ+o2dyfQhjJohHe1vi50Z4lrjBlMOOy+IY=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-ouqaLRfRlLZRzW4FFiVF4wmMj5xe5qTTcceceaNKenM=";
}
