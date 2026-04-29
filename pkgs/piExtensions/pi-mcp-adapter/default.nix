{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-mcp-adapter";
  version = "2026-04-29";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "4ca3799183710b459952655778f95b921e7985ad";
    sha256 = "sha256-rjgpPqxHjXDRU8z5oAdmsa33unuSVF+kaLiMtgddKQI=";
  };

  npmDepsHash = "sha256-6381oaQFwd9//E4iX7UqCHRSahB8H9yYmbvsp1+XY7w=";
}
