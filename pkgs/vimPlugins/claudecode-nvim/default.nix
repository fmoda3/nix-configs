{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "claudecode-nvim";
  version = "2026-06-02";
  src = fetchFromGitHub {
    owner = "coder";
    repo = "claudecode.nvim";
    rev = "781f3ab6c17f73e11794a651758275566b2fb167";
    sha256 = "sha256-+/I1ElBoo9x2vMresnKK+TIrrT/miwH8jU+GNSy/8j8=";
  };
  dependencies = [ vimPlugins.snacks-nvim ];
  meta.homepage = "https://github.com/coder/claudecode.nvim/";
}
