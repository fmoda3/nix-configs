{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "claudecode-nvim";
  version = "2026-06-15";
  src = fetchFromGitHub {
    owner = "coder";
    repo = "claudecode.nvim";
    rev = "e6c9dd4d4f144910b0066489100ad94b7133821f";
    sha256 = "sha256-pJtrh/3pGvALhQheB3LMB01IahTSYvxfCUNdiMvq8L0=";
  };
  dependencies = [ vimPlugins.snacks-nvim ];
  meta.homepage = "https://github.com/coder/claudecode.nvim/";
}
