{ fetchFromGitHub
, vimUtils
, vimPlugins
}:
vimUtils.buildVimPlugin {
  pname = "claudecode-nvim";
  version = "2026-11-01";
  src = fetchFromGitHub {
    owner = "coder";
    repo = "claudecode.nvim";
    rev = "96a47743fc9d48b263a996cddfe7b4e4bb3eb221";
    sha256 = "sha256-ZUChNosEQKEf8/JnSgqmh9GDne/YKpbMd/b68Bo/7xc=";
  };
  dependencies = [ vimPlugins.snacks-nvim ];
  meta.homepage = "https://github.com/coder/claudecode.nvim/";
}
