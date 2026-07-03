{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-mcp-adapter";
  version = "2026-07-03";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "87963d8a93282d1be967af4d2a22f836eb313852";
    sha256 = "sha256-ZuOHheuEkRj0e7TDZN8xH/n520vaenVWPA24ZfjYRbA=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-HsG10vyonNFfO3OisO0Yoz9Ee9QvE0nHhEdfmdeZNVM=";
}
