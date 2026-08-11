{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-08-10";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "2de5e7f343fa76bbb567e2e1c3bc11d06e44d42e";
    sha256 = "sha256-4KdCTOEPXo0rI6pl72ko9nhC8mXSOmza7BY1+4cjdjs=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-aYEtvHjSavKunv1Y9d1Yr/sbMPC23QgY+0vO66nSiOs=";
}
