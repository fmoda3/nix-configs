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
    rev = "ac8fe4c66264e30b267d39079fbe2fda1c37854f";
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
