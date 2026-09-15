{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-web-access";
  version = "2026-09-15";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "09cd27175d4a3088a43708041d935231187c5a97";
    sha256 = "sha256-fNB5UqtNP9BXuQKQp3R61rIDRBVhXu4ub++pvq7/pe8=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-0ScX5nMu3h8/KCysaeNiXj/DK7E3abY8LINAaAARhCc=";
}
