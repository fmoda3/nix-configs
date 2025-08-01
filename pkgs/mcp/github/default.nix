{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "github-mcp-server";
  version = "0.10.0";

  src = fetchFromGitHub {
    owner = "github";
    repo = "github-mcp-server";
    rev = "v${version}";
    hash = "sha256-I7Y2vZdQllT8wVttf+axwvBF7Cv4gYM4vxw7qKEmhog=";
  };

  vendorHash = "sha256-DeojCgMBwVclvoiEs462FoxIf3700XUjXvPbvRZE3CI=";

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
