{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "github-mcp-server";
  version = "0.15.0";

  src = fetchFromGitHub {
    owner = "github";
    repo = "github-mcp-server";
    rev = "v${version}";
    hash = "sha256-D6oEnaHrGnFfuO6NXRYbJ665OlWcwHo+JLfCPrdDkE4=";
  };

  vendorHash = "sha256-0QqgyjK3QID72aMI6l6ofXAUt94PYFqO8dWech7yaFw=";

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
