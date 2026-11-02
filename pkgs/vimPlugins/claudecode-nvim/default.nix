{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "claudecode-nvim";
  version = "2026-11-02";
  src = fetchFromGitHub {
    owner = "coder";
    repo = "claudecode.nvim";
    rev = "af04fbf9c27c5c06b4d1ff022b551aa94e1df4aa";
    sha256 = "sha256-yK+2tOIfMbRWUPL9LlyLMWvp/Jk7AwBskXVGtlV9Ldw=";
  };
  dependencies = [ vimPlugins.snacks-nvim ];
  meta.homepage = "https://github.com/coder/claudecode.nvim/";
}
