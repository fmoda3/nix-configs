{ fetchFromGitHub, vimUtils, ... }:
vimUtils.buildVimPluginFrom2Nix {
    pname = "nord-vim";
    version = "2022-01-25";
    src = fetchFromGitHub {
      owner = "arcticicestudio";
      repo = "nord-vim";
      rev = "b32592eb0842005d1d25de96e3964ccacd537039";
      sha256 = "0ji5nmybc0qqhwjz098h48wkmxvgcxpzz6xa5pdcfvk0sgnf28n3";
    };
    meta.homepage = "https://github.com/arcticicestudio/nord-vim/";
  }