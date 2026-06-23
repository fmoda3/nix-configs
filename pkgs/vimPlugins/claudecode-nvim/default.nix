{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "claudecode-nvim";
  version = "2026-06-23";
  src = fetchFromGitHub {
    owner = "coder";
    repo = "claudecode.nvim";
    rev = "288c9bf8834e5d7e401d1485fb5f684b1c2d7c72";
    sha256 = "sha256-ImhNKqVvwtevqLuvjLAlqS79j9XcgNU7jTN8+Z2Fhk0=";
  };
  dependencies = [ vimPlugins.snacks-nvim ];
  meta.homepage = "https://github.com/coder/claudecode.nvim/";
}
