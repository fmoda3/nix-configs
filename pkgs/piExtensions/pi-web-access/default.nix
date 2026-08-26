{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-08-25";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "08e347f4fe6bea807882c2363527118cce6eb539";
    sha256 = "sha256-Ad8H3vdY4zOivqqWhQd+FWhL0DGtFtGG4TY+w7eCFqk=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-RtgWHi3WIuMFtJzuEbL+Acbes8TTjoL4b9VeHODWCGI=";
}
