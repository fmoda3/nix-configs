{ fetchFromGitHub, vimUtils, ... }:
vimUtils.buildVimPluginFrom2Nix {
    pname = "cmp-nvim-lsp-signature-help";
    version = "2022-02-09";
    src = fetchFromGitHub {
      owner = "hrsh7th";
      repo = "cmp-nvim-lsp-signature-help";
      rev = "3f486a300c7f7296719c0705117afe24e3985766";
      sha256 = "0hy11yb2ym9yk8ixs3951qk0qa8w0gzsqcm9qrjpvhk55ygpzzxs";
    };
    meta.homepage = "https://github.com/hrsh7th/cmp-nvim-lsp-signature-help";
  }