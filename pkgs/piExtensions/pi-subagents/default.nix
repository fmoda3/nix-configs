{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-09-30";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "b6bda32f03b7f549623bc404c9be14dca298ddc4";
    sha256 = "sha256-QKf8Y8x90TLBKy3AkTRUc0+FxXAy/GKkHK2WQL2+a+k=";
  };

  npmDepsHash = "sha256-dLLyib2Bgz4bAdslKaiIhqd24eycuiHxpZWVdIpWPYg=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
