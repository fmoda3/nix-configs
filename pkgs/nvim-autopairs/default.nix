{ fetchFromGitHub, vimUtils, ... }:
vimUtils.buildVimPluginFrom2Nix {
    pname = "nvim-autopairs";
    version = "2022-03-06";
    src = fetchFromGitHub {
      owner = "windwp";
      repo = "nvim-autopairs";
      rev = "d2cde7c5802b34d6391a8a3555a3b7b56482f2aa";
      sha256 = "1cbijlqblxf5chc35lq8jl8pzfkx0a72bbf6bzz90nvrcn4xc6m3";
    };
    meta.homepage = "https://github.com/windwp/nvim-autopairs";
  }