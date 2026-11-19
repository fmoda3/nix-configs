{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-subagents";
  version = "2026-11-18";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "533033f0e906e85fdb0e909ce27a7c499ffb6485";
    sha256 = "sha256-LfOjBUWv9m/qY+M4SQNFSveYVrBV9pJVijtK+hUdArU=";
  };

  npmDepsHash = "sha256-baLawPHlhq6kOfJGmpsX8t3Qy5AdKOqMhfN8mrqqFnQ=";
  npmFlags = [ "--omit=dev" ];

  prunePaths = [ ".github" ];
}
