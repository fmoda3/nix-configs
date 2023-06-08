{ fetchFromGitHub, vimUtils, ... }:
vimUtils.buildVimPluginFrom2Nix {
  pname = "cmp-cmdline";
  version = "2023-04-2214";
  src = fetchFromGitHub {
    owner = "hrsh7th";
    repo = "cmp-cmdline";
    rev = "8ee981b4a91f536f52add291594e89fb6645e451";
    sha256 = "sha256-W8v/XhPjbvKSwCrfOAPihO2N9PEVnH5Cp/Fa25lNRw4=";
  };
  meta.homepage = "https://github.com/hrsh7th/cmp-cmdline/";
}
