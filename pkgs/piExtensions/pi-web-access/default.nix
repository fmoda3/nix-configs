{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-08-24";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "597be04626732e07fbef5632ac834deea745a0a8";
    sha256 = "sha256-CPTTasgpjK3fm8fj5sqCBPlIm0XlLxqTQGUaa8m3CVE=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-BJaGW1EfSTM7bWcSCq8R7AwtWYSsHgkYttxHyPGXcd4=";
}
