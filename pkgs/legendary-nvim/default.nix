{ fetchFromGitHub, vimUtils, ... }:
vimUtils.buildVimPluginFrom2Nix {
    pname = "legendary-nvim";
    version = "2022-02-09";
    src = fetchFromGitHub {
      owner = "mrjones2014";
      repo = "legendary.nvim";
      rev = "c2ef7d38ca2fd14e70644faf1ccf6c6021ac5c81";
      sha256 = "0z0g5b0da7pjn0w2jfsw1y1majjm9sxybg1kbm2mqxqp22zcibji";
    };
    meta.homepage = "https://github.com/mrjones2014/legendary.nvim";
  }