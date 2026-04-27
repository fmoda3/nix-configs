{ fetchFromGitHub
, vimUtils
}:
vimUtils.buildVimPlugin {
  pname = "lsp-document-highlight-nvim";
  version = "2026-04-27";
  src = fetchFromGitHub {
    owner = "akioweh";
    repo = "lsp-document-highlight.nvim";
    rev = "a6bf150e994aa56b8aecf0b242ca757c7ce7de1f";
    sha256 = "sha256-L41qTaJ4NKJ5TEEFB/6uOUQq1CB++oVgRiDuR7qoUo0=";
  };
  meta.homepage = "https://github.com/akioweh/lsp-document-highlight.nvim/";
}
