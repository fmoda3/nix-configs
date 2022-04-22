{ fetchFromGitHub, vimUtils, ... }:
vimUtils.buildVimPluginFrom2Nix {
    pname = "legendary-nvim";
    version = "2022-04-19";
    src = fetchFromGitHub {
      owner = "mrjones2014";
      repo = "legendary.nvim";
      rev = "77b7bc365c2470aff48b7398eb940e8c88789af3";
      sha256 = "0wxfwqs50jg59qf4lrbkbxpsh4f1kswmcfd01kvjz6wpnfg6c1b1";
    };
    meta.homepage = "https://github.com/mrjones2014/legendary.nvim";
  }