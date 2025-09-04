{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "claudecode-nvim";
  version = "2025-09-03";
  src = fetchFromGitHub {
    owner = "coder";
    repo = "claudecode.nvim";
    rev = "e21a837956c75dd5f617ce0fe80b054312c0829a";
    sha256 = "sha256-TaQpxncs+KaGdqOHiic+yxvzyhuk+0HlLPDqsuJDurg=";
  };
  dependencies = [ vimPlugins.snacks-nvim ];
  meta.homepage = "https://github.com/coder/claudecode.nvim/";
}
