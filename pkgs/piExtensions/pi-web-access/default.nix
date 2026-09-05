{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-09-05";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "8d1887fe60a0f9270742197660cf9738e5e5d32c";
    sha256 = "sha256-reD/oF6odsrvlAbpXyq1MKfZrfWFvjttrHX1fGXVTq0=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-jzFFgbGXn9wCD6p8IRO1fNEv1sTIpWpvlYmESW33kMk=";
}
