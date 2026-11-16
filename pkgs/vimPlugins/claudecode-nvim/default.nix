{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "claudecode-nvim";
  version = "2026-11-14";
  src = fetchFromGitHub {
    owner = "coder";
    repo = "claudecode.nvim";
    rev = "e864d9ddcd886154b3b824a90ce802e151acf268";
    sha256 = "sha256-EwR9IFpjPU55a25MpMqum5B2lfOT+Hsdrp8/o+tz594=";
  };
  dependencies = [ vimPlugins.snacks-nvim ];
  meta.homepage = "https://github.com/coder/claudecode.nvim/";
}
