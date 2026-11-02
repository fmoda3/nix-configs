{ buildPiExtension }:

let
  src = fetchGit {
    url = "git@github.toasttab.com:toasttab/pi-toast.git";
    rev = "303a0a2dd15610c6d75db4882d8a3113e86f3929";
    ref = "main";
    narHash = "sha256-+EA1eP7ZS0rQacURjVheJcLJqdywRzku7zttDU1DpbU=";
  };
in
buildPiExtension {
  pname = "pi-toast";
  version = "2026-10-30";

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
