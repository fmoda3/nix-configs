{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-09-05";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "3e242aa2dd017b3ef7d6e75e40a213d1a17ded57";
    sha256 = "sha256-oPRvBvAzdnPf6/Fhq5wSeUgtsbw8lZmQymJtzDzh3Ts=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-40wTpjxKcv5aZ+Jd6aaUtx4A+o3IcE+UvGRE5vAlB1Q=";
}
