{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "claudecode-nvim";
  version = "2025-01-16";
  src = fetchFromGitHub {
    owner = "coder";
    repo = "claudecode.nvim";
    rev = "91357d810ccf92f6169f3754436901c6ff5237ec";
    sha256 = "1hdzv8wjm0dgam7fimsm2h2kfnc8mp8gi7qyv4qddgfj7mir77l7";
  };
  dependencies = [ vimPlugins.snacks-nvim ];
  meta.homepage = "https://github.com/coder/claudecode.nvim/";
}
