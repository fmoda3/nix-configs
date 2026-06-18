{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "claudecode-nvim";
  version = "2026-06-18";
  src = fetchFromGitHub {
    owner = "coder";
    repo = "claudecode.nvim";
    rev = "bcb3fe205efe88771e8801d0a99b6fcb0a982bbb";
    sha256 = "sha256-pJtrh/3pGvALhQheB3LMB01IahTSYvxfCUNdiMvq8L0=";
  };
  dependencies = [ vimPlugins.snacks-nvim ];
  meta.homepage = "https://github.com/coder/claudecode.nvim/";
}
