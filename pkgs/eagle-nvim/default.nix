{ fetchFromGitHub
, vimUtils
}:
vimUtils.buildVimPlugin {
  pname = "eagle-nvim";
  version = "2025-05-08";
  src = fetchFromGitHub {
    owner = "soulis-1256";
    repo = "eagle.nvim";
    rev = "dd1a28c4d8626fbe85580b0a9ed8f88d77a26da1";
    sha256 = "sha256-u5Krlo8S4cH6JdBZzRGT4b7EkUUXmu3FihxYR1m9lwA=";
  };
  meta.homepage = "https://github.com/soulis-1256/eagle.nvim/";
}
