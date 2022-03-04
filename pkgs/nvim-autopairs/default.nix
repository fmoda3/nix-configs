{ fetchFromGitHub, vimUtils, ... }:
vimUtils.buildVimPluginFrom2Nix {
    pname = "nvim-autopairs";
    version = "2022-03-03";
    src = fetchFromGitHub {
      owner = "fmoda3";
      repo = "nvim-autopairs";
      rev = "4fc3c19d1c8cf5cf76d374fabce621fc35bcce02";
      sha256 = "0llfsq6qq3ylqmwxp30zibc1dmwm8g45q01wfwx6ix3dx4vb707r";
    };
    meta.homepage = "https://github.com/fmoda3/nvim-autopairs";
  }