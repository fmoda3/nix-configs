{ fetchFromGitHub, vimUtils, ... }:
vimUtils.buildVimPluginFrom2Nix {
    pname = "cmp-nvim-lsp-signature-help";
    version = "2022-02-15";
    src = fetchFromGitHub {
      owner = "hrsh7th";
      repo = "cmp-nvim-lsp-signature-help";
      rev = "7d6473ee5379a659e10abef4f5766a87ca41ec96";
      sha256 = "1rc6bay445iygwyf2yj5nh2rk355yjvasb430pvmqfixgh1mf5in";
    };
    meta.homepage = "https://github.com/hrsh7th/cmp-nvim-lsp-signature-help";
  }