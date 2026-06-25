{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "claudecode-nvim";
  version = "2026-06-25";
  src = fetchFromGitHub {
    owner = "coder";
    repo = "claudecode.nvim";
    rev = "2390c6e45c4789072c293ac69de051d169668b29";
    sha256 = "sha256-oMBPSRQFDmJ9Lq+ZP8vFMHaocm4sPX3D/orVMNwVXuM=";
  };
  dependencies = [ vimPlugins.snacks-nvim ];
  meta.homepage = "https://github.com/coder/claudecode.nvim/";
}
