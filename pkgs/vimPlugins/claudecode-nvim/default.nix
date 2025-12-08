{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "claudecode-nvim";
  version = "2025-12-09";
  src = fetchFromGitHub {
    owner = "coder";
    repo = "claudecode.nvim";
    rev = "6091df0e8edcdc92526cec23bbb42f63c0bb5ff2";
    sha256 = "sha256-PmSYIE7j9C2ckJc9wDIm4KCozXP0z1U9TOdItnDyoDQ=";
  };
  dependencies = [ vimPlugins.snacks-nvim ];
  meta.homepage = "https://github.com/coder/claudecode.nvim/";
}
