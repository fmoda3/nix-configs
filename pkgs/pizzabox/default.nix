{ lib, pkgs, ... }:

pkgs.python3Packages.buildPythonPackage rec {
  pname = "pizzabox";
  version = "0.1.0";

  src = fetchGit {
    url = "git@github.com:toasttab/pizzabox.git";
    rev = "d1f31a1017f085af1057b1d1ae1dca4906927d97";
    ref = "main";
  };

  buildInputs = with pkgs; [
    terminal-notifier
  ];

  doCheck = false;

  propagatedBuildInputs = with pkgs.python3Packages; [
    click
    pyyaml
    requests
    rich
    pyperclip
    jsons
    docker
  ];

}