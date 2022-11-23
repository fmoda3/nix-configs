{ config, pkgs, lib, ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableAutosuggestions = true;
    enableSyntaxHighlighting = true;
    dotDir = ".config/zsh";

    historySubstringSearch.enable = true;
    history = {
      expireDuplicatesFirst = true;
      extended = true;
    };

    localVariables = {
      GREP_COLOR = "1;33";
    };

    sessionVariables = lib.optionalAttrs config.my-home.isWork {
      TOAST_GIT = "/Users/frank/Development";
      DOCKER_HOST = "unix:///Users/frank/.local/share/containers/podman/machine/podman-machine-default/podman.sock";
    };

    shellAliases = {
      # PS
      psa = "ps aux";
      psg = "ps aux | grep ";

      # Moving around
      cdb = "cd -";

      # Show human friendly numbers and colors
      df = "df -h";
      ll = "ls -alGh";
      ls = "ls -Gh";
      du = "du -h -d 2";

      # show me files matching "ls grep"
      lsg = "ll | grep";

      # Git Aliases
      # Don't try to glob with zsh so you can do
      # stuff like ga *foo* and correctly have
      # git add the right stuff
      git = "noglob git";
      gs = "git status";
      gstsh = "git stash";
      gst = "git stash";
      gsp = "git stash pop";
      gsa = "git stash apply";
      gsh = "git show";
      gshw = "git show";
      gshow = "git show";
      gi = "vim .gitignore";
      gcm = "git ci -m";
      gcim = "git ci -m";
      gci = "git ci";
      gco = "git co";
      gcp = "git cp";
      ga = "git add -A";
      guns = "git unstage";
      gunc = "git uncommit";
      gm = "git merge";
      gms = "git merge --squash";
      gam = "git amend --reset-author";
      grv = "git remote -v";
      grr = "git remote rm";
      grad = "git remote add";
      gr = "git rebase";
      gra = "git rebase --abort";
      ggrc = "git rebase --continue";
      gbi = "git rebase --interactive";
      gl = "git l";
      glg = "git l";
      glog = "git l";
      co = "git co";
      gf = "git fetch";
      gfch = "git fetch";
      gd = "git diff";
      gb = "git b";
      gbd = "git b -D -w";
      gdc = "git diff --cached -w";
      gpub = "grb publish";
      gtr = "grb track";
      gpl = "git pull";
      gplr = "git pull --rebase";
      gps = "git push";
      gpsh = "git push";
      gnb = "git nb"; # new branch aka checkout -b
      grs = "git reset";
      grsh = "git reset --hard";
      gcln = "git clean";
      gclndf = "git clean -df";
      gclndfx = "git clean -dfx";
      gsm = "git submodule";
      gsmi = "git submodule init";
      gsmu = "git submodule update";
      gt = "git t";
      gbg = "git bisect good";
      gbb = "git bisect bad";

      # Common shell functions
      less = "less -r";
      tf = "tail -f";
      l = "less";
      lh = "ls -alt | head"; # see the last modified files
      cl = "clear";

      # Zippin
      gz = "tar -zcvf";

      # RM
      rm = "nocorrect rm"; # Override rm -i alias which makes rm prompt for every action

      # Misc
      caff = "caffeinate -d -i -m -s"; # Prevents computer from falling asleep
    };

    initExtra = ''
      eval "$(direnv hook zsh)"
      path+="/opt/homebrew/bin"
    '';
  };
}
