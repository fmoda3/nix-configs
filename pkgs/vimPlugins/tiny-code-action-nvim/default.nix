{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "tiny-code-action-nvim";
  version = "2025-06-21";
  src = fetchFromGitHub {
    owner = "rachartier";
    repo = "tiny-code-action.nvim";
    rev = "0896a8ea28e2a4462be6b6d26d30dc583441d9b9";
    sha256 = "sha256-aeeXtIuK0oLpyEfvCN6U6EZcYM2jyDWaFFBVGDVLEbo=";
  };
  dependencies = [ vimPlugins.plenary-nvim ];
  nvimSkipModules = [
    "tiny-code-action.previewers.snacks"
  ];
  meta.homepage = "https://github.com/rachartier/tiny-code-action.nvim/";
}
