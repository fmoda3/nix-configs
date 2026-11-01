{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "claudecode-nvim";
  version = "2026-11-01";
  src = fetchFromGitHub {
    owner = "coder";
    repo = "claudecode.nvim";
    rev = "6714ed528523d8c310e68d7c80a96b05ca9d0bad";
    sha256 = "sha256-UxEoP1hy3OHFwXmRifvV2RrFjZsLY5N85Ggh7uR4NpE=";
  };
  dependencies = [ vimPlugins.snacks-nvim ];
  meta.homepage = "https://github.com/coder/claudecode.nvim/";
}
