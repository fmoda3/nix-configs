{ fetchFromGitHub
, buildVimPluginFrom2Nix
}:

buildVimPluginFrom2Nix {
  pname = "cmp-nvim-lsp-signature-help";
  version = "2022-03-29";
  src = fetchFromGitHub {
    owner = "hrsh7th";
    repo = "cmp-nvim-lsp-signature-help";
    rev = "8014f6d120f72fe0a135025c4d41e3fe41fd411b";
    sha256 = "1k61aw9mp012h625jqrf311vnsm2rg27k08lxa4nv8kp6nk7il29";
  };
  meta.homepage = "https://github.com/hrsh7th/cmp-nvim-lsp-signature-help";
}