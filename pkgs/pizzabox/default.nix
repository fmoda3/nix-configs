{ lib, pkgs, ... }:

pkgs.python3Packages.buildPythonPackage rec {
  pname = "pizzabox";
  version = "0.1.0";

  src = fetchGit {
    url = "git@github.com:toasttab/pizzabox.git";
    rev = "60c04d4c41d66098da5f1a15231c5fa692e5779a";
    ref = "main";
  };

  doCheck = false;

  propagatedBuildInputs = with pkgs; with python3Packages; [
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
