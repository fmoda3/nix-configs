{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "claudecode-nvim";
  version = "2025-09-10";
  src = fetchFromGitHub {
    owner = "coder";
    repo = "claudecode.nvim";
    rev = "3e2601f1ac0eb61231ee6c6a7f9e8be82420f371";
    sha256 = "sha256-kMusHN2MSOH7GjDu/wX7jWhUezsj+pk8Yic8PRoUTsk=";
  };
  dependencies = [ vimPlugins.snacks-nvim ];
  meta.homepage = "https://github.com/coder/claudecode.nvim/";
}
