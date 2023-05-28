{ fetchFromGitHub, vimUtils, ... }:
vimUtils.buildVimPluginFrom2Nix {
  pname = "cmp-cmdline";
  version = "2023-04-2214";
  src = fetchFromGitHub {
    owner = "hrsh7th";
    repo = "cmp-cmdline";
    rev = "ba382eee7f21022f0bcbf1a83cd6d4766c1033a5";
    sha256 = "sha256-FHs5RGkBoz4VYsqeX522x3lm2M/y86njdRMv/0gwYuU=";
  };
  meta.homepage = "https://github.com/hrsh7th/cmp-cmdline/";
}
