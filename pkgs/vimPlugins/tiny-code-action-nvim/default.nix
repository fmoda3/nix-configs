{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "tiny-code-action-nvim";
  version = "2026-09-22";
  src = fetchFromGitHub {
    owner = "rachartier";
    repo = "tiny-code-action.nvim";
    rev = "91a9c32228e9a7761d241023d9ebb9d11d8fb10d";
    sha256 = "sha256-PLGomUsZt5KPabBtl1xof83sOxI7bv7DkHKjOnf8+/Q=";
  };
  dependencies = [ vimPlugins.plenary-nvim ];
  nvimSkipModules = [
    "tiny-code-action.previewers.snacks"
  ];
  meta.homepage = "https://github.com/rachartier/tiny-code-action.nvim/";
}
