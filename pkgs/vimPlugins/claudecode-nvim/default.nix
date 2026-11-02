{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "claudecode-nvim";
  version = "2026-11-01";
  src = fetchFromGitHub {
    owner = "coder";
    repo = "claudecode.nvim";
    rev = "9c11940c1aabd94db580816b58d1784d1992df17";
    sha256 = "sha256-dEv+4FlZ1iPEJLIwK+0rbPu/QJGn2EHe+6pa/aj274I=";
  };
  dependencies = [ vimPlugins.snacks-nvim ];
  meta.homepage = "https://github.com/coder/claudecode.nvim/";
}
