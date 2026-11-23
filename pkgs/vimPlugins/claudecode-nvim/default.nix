{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "claudecode-nvim";
  version = "2026-11-23";
  src = fetchFromGitHub {
    owner = "coder";
    repo = "claudecode.nvim";
    rev = "8bcc7bb816750405b624b4a4e05f9ef367715d1e";
    sha256 = "sha256-hYIloEXlQzH0SDbxJgsQqk9P5ZQWOHGQ8i3JsPC1RuY=";
  };
  dependencies = [ vimPlugins.snacks-nvim ];
  meta.homepage = "https://github.com/coder/claudecode.nvim/";
}
