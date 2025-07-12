{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "github-mcp-server";
  version = "0.7.0";

  src = fetchFromGitHub {
    owner = "github";
    repo = "github-mcp-server";
    rev = "v${version}";
    hash = "sha256-9IEsoIq4cuHgcYRuGEEkx5CFHaJzp0pNTpb1pNedzCE=";
  };

  vendorHash = "sha256-GYfK5QQH0DhoJqc4ynZBWuhhrG5t6KoGpUkZPSfWfEQ=";

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
