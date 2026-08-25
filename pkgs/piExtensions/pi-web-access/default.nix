{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-08-25";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "54c23531a5d249daebdccf061c9b28e65aca1d19";
    sha256 = "sha256-a7eIQ5ljZzWDHcP94i6cke6m05tQOKDHiGnDyVTzB6k=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-i59BU6ZrLgPcVhDvfYD+1gQU+bed4cNFSqZocQM9Xzw=";
}
