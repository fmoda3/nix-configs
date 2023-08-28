{ lib
, python3Packages
, terminal-notifier
, rsync
}:

python3Packages.buildPythonPackage rec {
  pname = "pizzabox";
  version = "0.1.0";

  src = fetchGit {
    url = "git@github.com:toasttab/pizzabox.git";
    rev = "c8a5b3f16f6c2649162075aaae5fa6d035db5f49";
    ref = "main";
  };

  doCheck = false;

  propagatedBuildInputs = with python3Packages; [
    terminal-notifier
    rsync
    click
    pyyaml
    requests
    rich
    pyperclip
    jsons
    docker
    watchdog
  ];

}
