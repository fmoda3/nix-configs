{ fetchFromGitHub, vimUtils, ... }:
vimUtils.buildVimPluginFrom2Nix {
  pname = "fidget-nvim";
  version = "2023-06-10";
  src = fetchFromGitHub {
    owner = "j-hui";
    repo = "fidget.nvim";
    rev = "90c22e47be057562ee9566bad313ad42d622c1d3";
    sha256 = "sha256-N3O/AvsD6Ckd62kDEN4z/K5A3SZNR15DnQeZhH6/Rr0=";
  };
  meta.homepage = "https://github.com/j-hui/fidget/";
}
