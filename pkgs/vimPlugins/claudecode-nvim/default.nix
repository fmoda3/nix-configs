{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "claudecode-nvim";
  version = "2026-06-15";
  src = fetchFromGitHub {
    owner = "coder";
    repo = "claudecode.nvim";
    rev = "2ee26319eb0c101fb2a6da1c9d6650dfa39363da";
    sha256 = "sha256-wf+O0PxSoslPkpn1owN2jGUiH0zN7o7hWcKAb6Pd5ns=";
  };
  dependencies = [ vimPlugins.snacks-nvim ];
  meta.homepage = "https://github.com/coder/claudecode.nvim/";
}
