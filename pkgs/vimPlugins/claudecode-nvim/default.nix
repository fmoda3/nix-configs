{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "claudecode-nvim";
  version = "2026-01-02";
  src = fetchFromGitHub {
    owner = "coder";
    repo = "claudecode.nvim";
    rev = "93f8e48b1f6cbf2469b378c20b3df4115252d379";
    sha256 = "sha256-dh7RrWezkmEtMKRasYCqfYanl6VxybC6Ra649H/KrPI=";
  };
  dependencies = [ vimPlugins.snacks-nvim ];
  meta.homepage = "https://github.com/coder/claudecode.nvim/";
}
