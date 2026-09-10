{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-09-10";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "734ab554d72693d934340f302e6bda8e46e39542";
    sha256 = "sha256-6xNWYZC7mY9XnVEwRCF7zEPGT71LoYlW43iyzR/I3so=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-40wTpjxKcv5aZ+Jd6aaUtx4A+o3IcE+UvGRE5vAlB1Q=";
}
