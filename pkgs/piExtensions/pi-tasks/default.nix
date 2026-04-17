{ buildNpmPackage
, fetchFromGitHub
}:
buildNpmPackage {
  pname = "pi-tasks";
  version = "2026-03-24";

  src = fetchFromGitHub {
    owner = "tintinweb";
    repo = "pi-tasks";
    rev = "46cca7a734bbeafb6db771eb06cb02b55b26e42d";
    sha256 = "sha256-tlRB2KcfX96n8XVm4cwgMcskJdA19WynR93ffVEGY88=";
  };

  npmDepsHash = "sha256-ng0q5Ml2hWPBV7cAnbqCRPukWCCC7WeANcEvyTYPO9c=";
  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r . $out/
    rm -rf $out/.github $out/test $out/media

    runHook postInstall
  '';
}
