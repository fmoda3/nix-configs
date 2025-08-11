{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "claudecode-nvim";
  version = "2025-08-11";
  src = fetchFromGitHub {
    owner = "coder";
    repo = "claudecode.nvim";
    rev = "985b4b117ea13ec85c92830ecac8f63543dd5ead";
    sha256 = "sha256-b4jCKIqowkVuWhI9jxthluZISBOnIc8eOIgkw5++HRY=";
  };
  dependencies = [ vimPlugins.snacks-nvim ];
  meta.homepage = "https://github.com/coder/claudecode.nvim/";
}
