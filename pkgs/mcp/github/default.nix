{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "github-mcp-server";
  version = "0.14.0";

  src = fetchFromGitHub {
    owner = "github";
    repo = "github-mcp-server";
    rev = "v${version}";
    hash = "sha256-IGjbuW4gPOZQrLMhyrZ3ii/GeRrgEyNVb0w3/Z0hihU=";
  };

  vendorHash = "sha256-F6PR4bxFSixgYQX65zjrVxcxEQxCoavQqa5mBGrZH8o=";

  subPackages = [ "cmd/github-mcp-server" ];

  meta = {
    description = "MCP server for GitHub API interactions";
    homepage = "https://github.com/github/github-mcp-server";
    license = lib.licenses.mit;
    mainProgram = "github-mcp-server";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    maintainers = with lib.maintainers; [ fmoda3 ];
  };
}
