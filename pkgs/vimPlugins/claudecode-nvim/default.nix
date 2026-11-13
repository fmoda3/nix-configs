{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "claudecode-nvim";
  version = "2026-11-12";
  src = fetchFromGitHub {
    owner = "coder";
    repo = "claudecode.nvim";
    rev = "ed1e0873eb9a659ec5b5aa7dab641edc4aef03d4";
    sha256 = "sha256-Gslf//OWnJl7FSzYbiWr+SXWyeW6mzC4Hz156vb3Qbg=";
  };
  dependencies = [ vimPlugins.snacks-nvim ];
  meta.homepage = "https://github.com/coder/claudecode.nvim/";
}
