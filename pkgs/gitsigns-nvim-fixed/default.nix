{ fetchFromGitHub, vimUtils, ... }:
vimUtils.buildVimPluginFrom2Nix {
  pname = "gitsigns-nvim-fixed";
  version = "2022-08-22";
  src = fetchFromGitHub {
    owner = "lewis6991";
    repo = "gitsigns.nvim";
    rev = "1e107c91c0c5e3ae72c37df8ffdd50f87fb3ebfa";
    sha256 = "0qg2y796mkkisyab6br4p0d6blx8ispglpphpdlmf14hp9si56bp";
  };
  meta.homepage = "https://github.com/lewis6991/gitsigns.nvim/";
}
