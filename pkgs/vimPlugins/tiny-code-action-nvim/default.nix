{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "tiny-code-action-nvim";
  version = "2025-08-20";
  src = fetchFromGitHub {
    owner = "rachartier";
    repo = "tiny-code-action.nvim";
    rev = "6f02cc30685c76812cdaa1bf1dc5f712d2265b14";
    sha256 = "sha256-d6oZ9FbSfC3jyRX6mLIqjfGedN/qXBGuv6RHQlY20v4=";
  };
  dependencies = [ vimPlugins.plenary-nvim ];
  nvimSkipModules = [
    "tiny-code-action.previewers.snacks"
  ];
  meta.homepage = "https://github.com/rachartier/tiny-code-action.nvim/";
}
