{ buildPiExtension }:

let
  src = fetchGit {
    url = "git@github.toasttab.com:toasttab/pi-toast.git";
    rev = "60ee8d504bda07cd6133d2901098e8f4f9fafbb7";
    ref = "main";
    narHash = "sha256-yfYKqaENCFrMPmOqy0PjbFOdAt+nqsksCfqmlS5Iig0=";
  };
in
buildPiExtension {
  pname = "pi-toast";
  version = "2026-10-15";

  inherit src;

  npmDepsHash = "sha256-wA4/+wrR5saFGMCSLpEJVs1X9Lvpe3vYAQZN1TWFsKI=";

  prunePaths = [
    ".github"
    "test"
  ];

  # fetchGit strips .git, so pi-toast's telemetry can't read its own commit
  # (pi_toast.commit). A detached HEAD holding the pinned rev is all it reads.
  postInstallCommands = ''
    mkdir -p "$out/.git"
    echo "${src.rev}" > "$out/.git/HEAD"
  '';
}
