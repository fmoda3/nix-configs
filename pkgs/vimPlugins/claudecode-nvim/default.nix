{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "claudecode-nvim";
  version = "2026-06-08";
  src = fetchFromGitHub {
    owner = "coder";
    repo = "claudecode.nvim";
    rev = "0a24f8ba609c99e73a383bc16485a44a6f1e2dfe";
    sha256 = "sha256-fFUpF67HFBYZXiJcnc123r8Po4uxm6vlZMfPK35sHHY=";
  };
  dependencies = [ vimPlugins.snacks-nvim ];
  meta.homepage = "https://github.com/coder/claudecode.nvim/";
}
