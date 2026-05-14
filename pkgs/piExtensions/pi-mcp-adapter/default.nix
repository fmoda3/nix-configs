{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-mcp-adapter";
  version = "2026-05-13";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "8c1a28e7ebb837d5fa03de3a67f217ce994782cc";
    sha256 = "sha256-jW/vlQ4ay3Le8PRlH3UMYJVhfJYFCxY6frPZCIs/osI=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-X7rOmOkL9dF9qBITaMaA+iAQ4TKY+SM7SywtA84crKs=";
}
