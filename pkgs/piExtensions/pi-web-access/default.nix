{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-09-06";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "811ef82a6dd04fe4abd73fa40b079aa39ee1870d";
    sha256 = "sha256-pRAya3k3gFSZ9dOqUq5aBf3UaNbpeD2Q0LB+c0J8mvE=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-40wTpjxKcv5aZ+Jd6aaUtx4A+o3IcE+UvGRE5vAlB1Q=";
}
