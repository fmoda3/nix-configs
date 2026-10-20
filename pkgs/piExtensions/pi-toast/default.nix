{ buildPiExtension }:

let
  src = fetchGit {
    url = "git@github.toasttab.com:toasttab/pi-toast.git";
    rev = "e643dc88f4c6392cb640904aa2896b219a69bc3d";
    ref = "main";
    narHash = "sha256-vDzX01Jp+mKqWPx+gjMAzE/yQSrNwCMky3VbOanAbpw=";
  };
in
buildPiExtension {
  pname = "pi-toast";
  version = "2026-10-20";

  inherit src;

  npmDepsHash = "sha256-s22INags8/LWJ0S6ua0VT9pircNeO77ZXpirR4ARCdc=";

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
