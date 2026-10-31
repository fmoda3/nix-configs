{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "claudecode-nvim";
  version = "2026-10-31";
  src = fetchFromGitHub {
    owner = "coder";
    repo = "claudecode.nvim";
    rev = "82b5f40ce31f25e95b80686b3fc3a6f01c666321";
    sha256 = "sha256-b7ina2PhNl6HipAdYLYGkd5IsY5JXZd/WA6tSKERp0g=";
  };
  dependencies = [ vimPlugins.snacks-nvim ];
  meta.homepage = "https://github.com/coder/claudecode.nvim/";
}
