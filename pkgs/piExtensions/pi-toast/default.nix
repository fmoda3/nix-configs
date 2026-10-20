{ buildPiExtension }:

let
  src = fetchGit {
    url = "git@github.toasttab.com:toasttab/pi-toast.git";
    rev = "94ab90267d3107b350d423a0fae220a14b1417e1";
    ref = "main";
    narHash = "sha256-OrSbzQQXLHSuB6g6lxv19K41mYcBUOV+/9pMa+yU65s=";
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
