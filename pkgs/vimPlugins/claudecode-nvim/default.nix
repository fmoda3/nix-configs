{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "claudecode-nvim";
  version = "2026-06-03";
  src = fetchFromGitHub {
    owner = "coder";
    repo = "claudecode.nvim";
    rev = "8ec321279d3d9eddb0ce5f52d4b0d051dafb5743";
    sha256 = "sha256-l/PcQlCSQKr0aSfnPUwRf7rY6QAx9u5twYsSX72B4xI=";
  };
  dependencies = [ vimPlugins.snacks-nvim ];
  meta.homepage = "https://github.com/coder/claudecode.nvim/";
}
