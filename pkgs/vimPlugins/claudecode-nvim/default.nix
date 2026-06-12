{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "claudecode-nvim";
  version = "2026-06-12";
  src = fetchFromGitHub {
    owner = "coder";
    repo = "claudecode.nvim";
    rev = "7c7d47e75d1c8597a676ca20b36a8b85a776ac61";
    sha256 = "sha256-INQAg5q5eSzZkC/RJPwd4R9fNKrwUYcsN/AaVT6saNE=";
  };
  dependencies = [ vimPlugins.snacks-nvim ];
  meta.homepage = "https://github.com/coder/claudecode.nvim/";
}
