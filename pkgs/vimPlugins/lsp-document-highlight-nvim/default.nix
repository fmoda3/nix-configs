{ fetchFromGitHub
, vimUtils
}:
vimUtils.buildVimPlugin {
  pname = "lsp-document-highlight-nvim";
  version = "2026-09-12";
  src = fetchFromGitHub {
    owner = "akioweh";
    repo = "lsp-document-highlight.nvim";
    rev = "2097274ed9339beb36bb37cec3fe46890a970a2f";
    sha256 = "sha256-KjwbH5sMLZfDmKpgEgIowUu1PqfZkNbRH4Ci3B03oyY=";
  };
  meta.homepage = "https://github.com/akioweh/lsp-document-highlight.nvim/";
}
