{ fetchFromGitHub
, vimUtils
}:
vimUtils.buildVimPlugin {
  pname = "lsp-document-highlight-nvim";
  version = "2026-01-10";
  src = fetchFromGitHub {
    owner = "akioweh";
    repo = "lsp-document-highlight.nvim";
    rev = "8d49ad5b8b06ad496ff26e45879aaff37f2a210c";
    sha256 = "sha256-pKmivLGsttX+w7E7WSPlsEJ9JUpl0DuFMnsyUsWKTVY=";
  };
  meta.homepage = "https://github.com/akioweh/lsp-document-highlight.nvim/";
}
