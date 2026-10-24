{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "claudecode-nvim";
  version = "2026-10-24";
  src = fetchFromGitHub {
    owner = "coder";
    repo = "claudecode.nvim";
    rev = "c0deb41a0c6ac74c620be0a683aa9834e535c84a";
    sha256 = "sha256-DnwtpsIszWXPwSrCgXhp8gb7F7uoL/9Ecl77DAf6qos=";
  };
  dependencies = [ vimPlugins.snacks-nvim ];
  meta.homepage = "https://github.com/coder/claudecode.nvim/";
}
