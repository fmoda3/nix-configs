{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "tiny-code-action-nvim";
  version = "2026-01-19";
  src = fetchFromGitHub {
    owner = "rachartier";
    repo = "tiny-code-action.nvim";
    rev = "6ded5f7cf53e8d804ab4fdc1d728f47ab772007e";
    sha256 = "sha256-LSQfmoo7Hw043QdajFikbs7X5YeIWI5dbsRKFRG4U7c=";
  };
  dependencies = [ vimPlugins.plenary-nvim ];
  nvimSkipModules = [
    "tiny-code-action.previewers.snacks"
  ];
  meta.homepage = "https://github.com/rachartier/tiny-code-action.nvim/";
}
