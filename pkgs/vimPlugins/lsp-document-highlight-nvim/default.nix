{ fetchFromGitHub
, vimUtils
}:
vimUtils.buildVimPlugin {
  pname = "lsp-document-highlight-nvim";
  version = "2026-09-17";
  src = fetchFromGitHub {
    owner = "akioweh";
    repo = "lsp-document-highlight.nvim";
    rev = "caa560dcdc046f07a8b782c1f5a10c03740acb87";
    sha256 = "sha256-ut5AVUWbIwHuhKwBYH+mgCNOl7oQVN1qX9g3r/p6A7Q=";
  };
  meta.homepage = "https://github.com/akioweh/lsp-document-highlight.nvim/";
}
