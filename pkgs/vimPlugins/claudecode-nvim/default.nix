{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "claudecode-nvim";
  version = "2025-09-29";
  src = fetchFromGitHub {
    owner = "coder";
    repo = "claudecode.nvim";
    rev = "ac2baef386d8078ef2a0aaa98580d25ec178f40a";
    sha256 = "sha256-RnMcLYjffkK4ImJ1eKrVzNRUQKD9uo0o84Tf+/LxFbM=";
  };
  dependencies = [ vimPlugins.snacks-nvim ];
  meta.homepage = "https://github.com/coder/claudecode.nvim/";
}
