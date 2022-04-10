{ buildPythonPackage
, fetchGit
, terminal-notifier
, rsync
, click
, pyyaml
, requests
, rich
, pyperclip
, jsons
, docker
, watchdog
}:

buildPythonPackage rec {
  pname = "pizzabox";
  version = "0.1.0";

  src = fetchGit {
    url = "git@github.com:toasttab/pizzabox.git";
    rev = "69fb13fe8bc3b4736f20fda34f98fb158538c2df";
    ref = "main";
  };

  doCheck = false;

  propagatedBuildInputs = [
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