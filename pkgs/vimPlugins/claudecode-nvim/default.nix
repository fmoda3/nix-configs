{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "claudecode-nvim";
  version = "2026-06-22";
  src = fetchFromGitHub {
    owner = "coder";
    repo = "claudecode.nvim";
    rev = "298a3e6cbe784ed9c0cc5ff85aab6be6d704d2cd";
    sha256 = "sha256-zWIdeSn0t+bJfCLHQz4JCg7T5Tam70uWoqGvYl/yPqQ=";
  };
  dependencies = [ vimPlugins.snacks-nvim ];
  meta.homepage = "https://github.com/coder/claudecode.nvim/";
}
