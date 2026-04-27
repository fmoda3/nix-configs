{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "claudecode-nvim";
  version = "2026-04-27";
  src = fetchFromGitHub {
    owner = "coder";
    repo = "claudecode.nvim";
    rev = "102d835c964069c9c5e37abaf05ae4f9c3ee6f00";
    sha256 = "sha256-h8wYaWBKjKrb7hYYKYs5yUS5RI0JVFo8Emcy99YK6Qw=";
  };
  dependencies = [ vimPlugins.snacks-nvim ];
  meta.homepage = "https://github.com/coder/claudecode.nvim/";
}
