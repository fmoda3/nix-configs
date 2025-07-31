{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "claudecode-nvim";
  version = "2025-07-30";
  src = fetchFromGitHub {
    owner = "coder";
    repo = "claudecode.nvim";
    rev = "d0f97489d9064bdd55592106e99aa5f355a09914";
    sha256 = "sha256-qmZPjZJ9UFxAWCY3NQwsu0nEniG/UasV/iCrG3S5tPQ=";
  };
  dependencies = [ vimPlugins.snacks-nvim ];
  meta.homepage = "https://github.com/coder/claudecode.nvim/";
}
