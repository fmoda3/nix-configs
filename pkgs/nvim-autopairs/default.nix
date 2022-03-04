{ fetchFromGitHub, vimUtils, ... }:
vimUtils.buildVimPluginFrom2Nix {
    pname = "nvim-autopairs";
    version = "2022-03-04";
    src = fetchFromGitHub {
      owner = "windwp";
      repo = "nvim-autopairs";
      rev = "7bc61885cca93958a5e6de4873f4b930e87c6f9f";
      sha256 = "0fkpf2r3plmgzxkzglxgrw6gq14ak4kyvwmp1kcdwgrqb3d0nf8p";
    };
    meta.homepage = "https://github.com/windwp/nvim-autopairs";
  }