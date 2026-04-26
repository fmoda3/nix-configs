{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-04-26";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "0878e60abcd82059faeae85808ee59796ccc07c5";
    sha256 = "sha256-GHqLNIqi3ERib2HLGoDtVCgOEDf3SVmczHYkhgxqgMg=";
  };

  prunePaths = [ ".github" ];
}
