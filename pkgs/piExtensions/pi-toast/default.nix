{ buildPiExtension }:

let
  src = fetchGit {
    url = "git@github.toasttab.com:toasttab/pi-toast.git";
    rev = "5a36954650e8593c00cd0dae2367a0d606fde05a";
    ref = "main";
    narHash = "sha256-Cwv7JlPoxc7pIEsOV8eAeuRWysGfq9IxeBwKDk8L1z0=";
  };
in
buildPiExtension {
  pname = "pi-toast";
  version = "2026-10-30";

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
