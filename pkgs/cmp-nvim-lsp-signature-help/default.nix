{ fetchFromGitHub, vimUtils, ... }:
vimUtils.buildVimPluginFrom2Nix {
    pname = "cmp-nvim-lsp-signature-help";
    version = "2022-02-15";
    src = fetchFromGitHub {
      owner = "hrsh7th";
      repo = "cmp-nvim-lsp-signature-help";
      rev = "414619286928901600cf5b5ccb2f62666f82d3bd";
      sha256 = "0ly41w9x7ygi0ii8i9k56g5p2sdxn345rf21rb7asnlck1ahc0r1";
    };
    meta.homepage = "https://github.com/hrsh7th/cmp-nvim-lsp-signature-help";
  }