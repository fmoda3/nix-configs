{ lib, pkgs, ... }:

pkgs.python3Packages.buildPythonPackage rec {
  pname = "pizzabox";
  version = "0.1.0";

  src = fetchGit {
    url = "git@github.com:toasttab/pizzabox.git";
    rev = "c19d244605669d007461e16f219f29b13d3b9596";
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