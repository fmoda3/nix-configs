{ fetchFromGitHub, vimUtils, ... }:
vimUtils.buildVimPluginFrom2Nix {
    pname = "legendary-nvim";
    version = "2022-02-16";
    src = fetchFromGitHub {
      owner = "mrjones2014";
      repo = "legendary.nvim";
      rev = "8be2a9fc80a9ddc33d2d34b82161c8a4a04a82cd";
      sha256 = "15h9l5q7bidd0knwcyl3ny8rrlplwykazdg44l335d6607czlccp";
    };
    meta.homepage = "https://github.com/mrjones2014/legendary.nvim";
  }