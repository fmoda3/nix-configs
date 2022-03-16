{ lib, pkgs, ... }:

pkgs.python3Packages.buildPythonPackage rec {
  pname = "pizzabox";
  version = "0.1.0";

  src = fetchGit {
    url = "git@github.com:toasttab/pizzabox.git";
    rev = "91cb7a337bb691154236c855c2b21e40b481d04e";
    ref = "main";
  };

  doCheck = false;

  propagatedBuildInputs = with pkgs; with python3Packages; [
    terminal-notifier
    click
    pyyaml
    requests
    rich
    pyperclip
    jsons
    docker
  ];

}