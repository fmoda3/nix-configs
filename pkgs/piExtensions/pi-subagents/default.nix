{ lib
, stdenvNoCC
, fetchFromGitHub
}:
stdenvNoCC.mkDerivation {
  pname = "pi-subagents";
  version = "2026-04-23";

  src = fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-subagents";
    rev = "9711a40f71d93acfd0e3712e1f036c8756ac88c9";
    sha256 = "sha256-KkjB5x0d9b+0vkVhnjzVdjvcoVOyjCAiJfF8JurRAMw=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github

    runHook postInstall
  '';
}
