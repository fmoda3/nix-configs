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
    rev = "8307fdff5cc125a449fba1fedfa6356143a5f8c3";
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
