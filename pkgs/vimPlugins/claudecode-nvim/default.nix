{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "claudecode-nvim";
  version = "2025-08-04";
  src = fetchFromGitHub {
    owner = "coder";
    repo = "claudecode.nvim";
    rev = "477009003cbec7e6088dbbeab46aba80f461d5f0";
    sha256 = "sha256-P2FELIY8roeII4kVgk5BEHWkhelJCsaV6PyMIkEpC8I=";
  };
  dependencies = [ vimPlugins.snacks-nvim ];
  meta.homepage = "https://github.com/coder/claudecode.nvim/";
}
