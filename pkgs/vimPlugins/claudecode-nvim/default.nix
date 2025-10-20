{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "claudecode-nvim";
  version = "2025-10-19";
  src = fetchFromGitHub {
    owner = "coder";
    repo = "claudecode.nvim";
    rev = "1552086ebcce9f4a2ea3b9793018a884d6b60169";
    sha256 = "sha256-XYmf1RQ2bVK6spINZW4rg6OQQ5CWWcR0Tw4QX8ZDjgs=";
  };
  dependencies = [ vimPlugins.snacks-nvim ];
  meta.homepage = "https://github.com/coder/claudecode.nvim/";
}
