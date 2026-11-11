{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-claude-bridge";
  version = "0.12.0";

  src = fetchFromGitHub {
    owner = "elidickinson";
    repo = "pi-claude-bridge";
    tag = "v0.12.0";
    sha256 = "sha256-XRe0dQsRs7Hmu/gQWrY8Og885DHFFVD72oapDmYvcRE=";
  };

  npmDepsHash = "sha256-cpMJpUqJgGFW3dxUDrQnkXDUAZivqcGranBRFaZ6N7o=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
