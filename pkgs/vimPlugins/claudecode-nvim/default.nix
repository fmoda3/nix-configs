{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "claudecode-nvim";
  version = "2026-01-26";
  src = fetchFromGitHub {
    owner = "coder";
    repo = "claudecode.nvim";
    rev = "aa9a5cebebdbfa449c1c5ff229ba5d98e66bafed";
    sha256 = "sha256-B6BA+3h7RLmk+zk6O365DmY06ALdbbkFBmOaRH9muog=";
  };
  dependencies = [ vimPlugins.snacks-nvim ];
  meta.homepage = "https://github.com/coder/claudecode.nvim/";
}
