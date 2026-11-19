{ buildPiExtension }:

let
  src = fetchGit {
    url = "ssh://git@github.toasttab.com/toasttab/pi-toast.git";
    rev = "c04b80953504fb94a00a13d5aa832d17306e3f22";
    ref = "main";
    narHash = "sha256-1Qx2uz7ji/d3wdx2k4ZSOAD3PCkpvwzYdMHeQ/xe+9A=";
  };
in
buildPiExtension {
  pname = "pi-toast";
  version = "2026-11-18";

  inherit src;

  npmDepsHash = "sha256-y523EPcHA4lBEt0SGZ9uckwn/YpgIUwbA58gXfEpmwE=";

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
