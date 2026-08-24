{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-08-24";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "83a34659d2ba4cbc1d344f1f640078911bbd3446";
    sha256 = "sha256-3sKPFVvTIPSB4+BUd1Be9mxYTKTiOVdWO0hfA5XSZ+w=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-BJaGW1EfSTM7bWcSCq8R7AwtWYSsHgkYttxHyPGXcd4=";
}
