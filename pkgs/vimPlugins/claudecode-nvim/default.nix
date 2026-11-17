{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "claudecode-nvim";
  version = "2026-11-16";
  src = fetchFromGitHub {
    owner = "coder";
    repo = "claudecode.nvim";
    rev = "6ad8e0fdbda84486f13f7f1fa4802942f4877f13";
    sha256 = "sha256-omHrOlIFqRbiEO3Oqr5DNnlq04C69bzS567PgplBGKc=";
  };
  dependencies = [ vimPlugins.snacks-nvim ];
  meta.homepage = "https://github.com/coder/claudecode.nvim/";
}
