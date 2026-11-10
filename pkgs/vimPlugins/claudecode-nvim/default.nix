{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "claudecode-nvim";
  version = "2026-11-09";
  src = fetchFromGitHub {
    owner = "coder";
    repo = "claudecode.nvim";
    rev = "d721d726276c2fa0bf5b689de247c368c1e40265";
    sha256 = "sha256-ZTz2knO3rOCSXfP7dYuBpoHE6+ZuqRMh/yMeBkVhovk=";
  };
  dependencies = [ vimPlugins.snacks-nvim ];
  meta.homepage = "https://github.com/coder/claudecode.nvim/";
}
