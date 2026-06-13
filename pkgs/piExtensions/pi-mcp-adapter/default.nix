{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-mcp-adapter";
  version = "2026-06-13";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "a764c25609d8daf76e607bc99557621fc3ed8aa9";
    sha256 = "sha256-MrorLzxbn3O81B47Nd0d0xnd0xhXgMdobnXgD0axldE=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-HsG10vyonNFfO3OisO0Yoz9Ee9QvE0nHhEdfmdeZNVM=";
}
