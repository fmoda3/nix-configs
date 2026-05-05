{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-mcp-adapter";
  version = "2026-05-05";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "184d3cb75fa017b8badf657622b4b7efbf85cfb6";
    sha256 = "sha256-1FW6ebPphCfG8ubz1lWvBAhtQV0Vp4ChF+LoEt8JExU=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-ohkQqvnioQ65JY/qyrheGWzjLhivRLRrGYXSq7oc5uE=";
}
