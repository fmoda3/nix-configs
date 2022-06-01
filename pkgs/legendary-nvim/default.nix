{ fetchFromGitHub, vimUtils, ... }:
vimUtils.buildVimPluginFrom2Nix {
    pname = "legendary-nvim";
    version = "2022-05-20";
    src = fetchFromGitHub {
      owner = "mrjones2014";
      repo = "legendary.nvim";
      rev = "3d6cde24296b017412bf8801db6e6777478682eb";
      sha256 = "16jyyrm7gij4djdg1hlp05v6x053f0cdjzync741di31fbnnjcy5";
    };
    meta.homepage = "https://github.com/mrjones2014/legendary.nvim";
  }