{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "claudecode-nvim";
  version = "2026-06-09";
  src = fetchFromGitHub {
    owner = "coder";
    repo = "claudecode.nvim";
    rev = "7b8b7090c16f4151401a281741a4bf37050ebd26";
    sha256 = "sha256-NHhoAqCTa1+go+DYFj25eH0ZDmAqbA9tpHtj3IarCUU=";
  };
  dependencies = [ vimPlugins.snacks-nvim ];
  meta.homepage = "https://github.com/coder/claudecode.nvim/";
}
