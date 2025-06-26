{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "tiny-code-action-nvim";
  version = "2025-06-25";
  src = fetchFromGitHub {
    owner = "rachartier";
    repo = "tiny-code-action.nvim";
    rev = "402794fa049c77d24409d68fca3475c5471069d4";
    sha256 = "sha256-QEnB50d5SRFb133WMvFZSE8Wf2/MXqPhAiK8nhzwr3c=";
  };
  dependencies = [ vimPlugins.plenary-nvim ];
  nvimSkipModules = [
    "tiny-code-action.previewers.snacks"
  ];
  meta.homepage = "https://github.com/rachartier/tiny-code-action.nvim/";
}
