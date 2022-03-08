{ fetchFromGitHub, vimUtils, ... }:
vimUtils.buildVimPluginFrom2Nix {
    pname = "legendary-nvim";
    version = "2022-02-16";
    src = fetchFromGitHub {
      owner = "mrjones2014";
      repo = "legendary.nvim";
      rev = "a06bffa8a1407ae846a580afc55227275a998892";
      sha256 = "0prf8q20j2qy85mgvd2mf1i41nmkq9bnn4i6n70kpp4l9yhinbyp";
    };
    meta.homepage = "https://github.com/mrjones2014/legendary.nvim";
  }