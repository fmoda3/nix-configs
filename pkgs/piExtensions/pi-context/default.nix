{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-context";
  version = "2026-05-22";

  src = fetchFromGitHub {
    owner = "ttttmr";
    repo = "pi-context";
    rev = "2f80ef3d065c94da0e9f56ae3f65b54da241e378";
    sha256 = "sha256-Yh09t5JuTjbiFg8Fp/AMkV5N1v/OLd5YKD7YHBzVtlw=";
  };

  prunePaths = [ ".github" ];
}
