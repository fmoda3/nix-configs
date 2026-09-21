{ fetchFromGitHub
, vimUtils
}:
vimUtils.buildVimPlugin {
  pname = "lsp-document-highlight-nvim";
  version = "2026-09-21";
  src = fetchFromGitHub {
    owner = "akioweh";
    repo = "lsp-document-highlight.nvim";
    rev = "09ee8762e5296307f7f6664159fd79f0258c8c20";
    sha256 = "sha256-UaZaM0RXYXbIidd5sxuFzRIdahKJ3R+gKWBwmL7iiEA=";
  };
  meta.homepage = "https://github.com/akioweh/lsp-document-highlight.nvim/";
}
