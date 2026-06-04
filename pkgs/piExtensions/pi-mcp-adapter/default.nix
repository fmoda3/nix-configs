{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-mcp-adapter";
  version = "2026-06-04";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "07565c689c8fb6dabe0815a9c6f13689eb61c987";
    sha256 = "sha256-dNqIKGCJrQDL8njZut6TeOht52Ak7GBULO07jmTl7Pc=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-jBPBru286ywysFKiEwhyurvJl/Waopykzl1h7yFOPp8=";
}
