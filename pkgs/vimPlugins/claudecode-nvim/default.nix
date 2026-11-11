{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "claudecode-nvim";
  version = "2026-11-11";
  src = fetchFromGitHub {
    owner = "coder";
    repo = "claudecode.nvim";
    rev = "9a50293d2aba3f089ba72a2fa7101516eb2b0e1d";
    sha256 = "sha256-Dm1w16DKDSeWoeCqmUQhxU7ZJwKQ9lQIq+3Q2sJMP0s=";
  };
  dependencies = [ vimPlugins.snacks-nvim ];
  meta.homepage = "https://github.com/coder/claudecode.nvim/";
}
