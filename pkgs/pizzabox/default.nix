{ lib
, python3Packages
, terminal-notifier
, rsync
}:

python3Packages.buildPythonPackage rec {
  pname = "pizzabox";
  version = "0.1.0";

  src = fetchGit {
    url = "git@github.toasttab.com:toasttab/pizzabox.git";
    rev = "6bc630ddd9eb5a292db8d489051c24d784df4997";
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
