{ fetchFromGitHub
, vimUtils
}:
vimUtils.buildVimPlugin {
  pname = "lsp-document-highlight-nvim";
  version = "2026-09-14";
  src = fetchFromGitHub {
    owner = "akioweh";
    repo = "lsp-document-highlight.nvim";
    rev = "bdc7ab26b3360c43dfe0b354414e628ba95ab506";
    sha256 = "sha256-6XohY0yHKqizEBa6qQcyWo8lCPdoFrSMgGm7MlzSN3A=";
  };
  meta.homepage = "https://github.com/akioweh/lsp-document-highlight.nvim/";
}
