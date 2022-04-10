{ fetchFromGitHub
, buildVimPluginFrom2Nix
}:

buildVimPluginFrom2Nix {
  pname = "legendary-nvim";
  version = "2022-04-04";
  src = fetchFromGitHub {
    owner = "mrjones2014";
    repo = "legendary.nvim";
    rev = "c70d8cd627c26f169c839e4b089c0b4dc53fbe13";
    sha256 = "1a3bvh5ybifrsinsly0pz4p2bxs3ssh9883g8hncvdv8z5lr3qj7";
  };
  meta.homepage = "https://github.com/mrjones2014/legendary.nvim";
}