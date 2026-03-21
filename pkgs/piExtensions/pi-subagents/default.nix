{ stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-subagents";
  version = "2026-03-21";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "ed5673f8df10719cad223db84cf2b631b01dffd6";
    sha256 = "sha256-byJm0xyqYOfRsCJJfUQQyA/NqJeC3BRufmqyE2AiGd0=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
