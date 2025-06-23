{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "github-mcp-server";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "github";
    repo = "github-mcp-server";
    rev = "v${version}";
    hash = "sha256-dbzO8yTAIfdAwcZEdoJqp+loPQea8iRSsAHdk2DfZ2A=";
  };

  vendorHash = "sha256-gVR7Md3xYrPpeMhHRTKCQKCJvRRIl85uXo+QwlVaPzk=";

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
