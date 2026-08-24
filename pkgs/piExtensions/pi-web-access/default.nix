{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-08-24";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "d327e4299e43014586eee2bf7b637baae9047d38";
    sha256 = "sha256-Whhy9RJ2AGzRZKgUmOpJ8SSOP2NOA9QzAouFHMoIOPk=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-BJaGW1EfSTM7bWcSCq8R7AwtWYSsHgkYttxHyPGXcd4=";
}
