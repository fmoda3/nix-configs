{ fetchFromGitHub, vimUtils, ... }:
vimUtils.buildVimPluginFrom2Nix {
    pname = "legendary-nvim";
    version = "2022-02-16";
    src = fetchFromGitHub {
      owner = "mrjones2014";
      repo = "legendary.nvim";
      rev = "219a558d5a316ff8a70b4bdf98cb52345f1d0436";
      sha256 = "0ylcpxq8m86jz6dm039rcmw70iynjla0vyvq3l9wmq9bavxh1cbj";
    };
    meta.homepage = "https://github.com/mrjones2014/legendary.nvim";
  }