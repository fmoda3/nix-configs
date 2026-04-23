{ buildNpmPackage
, fetchFromGitHub
}:
buildNpmPackage {
  pname = "pi-mcp-adapter";
  version = "2026-04-23";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "b1dd619fed04589c1f4d967284758d8b4c6722c6";
    sha256 = "sha256-sD06qwePUJlJ9SUTmclXWU5+Ufssn0kZYCkhx9P13MQ=";
  };

  npmDepsHash = "sha256-ehVDVQTLKDZNgKwm6ICnUl45MDN73hY95fDhYwMybbM=";
  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/

    runHook postInstall
  '';
}
