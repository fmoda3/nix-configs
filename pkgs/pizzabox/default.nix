{ lib, pkgs, ... }:

pkgs.python3Packages.buildPythonPackage rec {
  pname = "pizzabox";
  version = "0.1.0";

  src = fetchGit {
    url = "git@github.com:toasttab/pizzabox.git";
    rev = "edb0d0090178df727e119b5cef00c6a47105e7a6";
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
