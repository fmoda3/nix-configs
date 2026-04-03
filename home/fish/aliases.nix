{ pkgs, lib, ... }:
let
  # Aliases: transparent tool replacements where expansion would be noisy.
  # These silently swap one tool for another; history shows the alias name.
  commonAliases = {
    # Replace ls with eza
    ls = "eza";

    # Replace tree with eza
    tree = "eza --tree";

    # Grep with color
    grep = "grep --color=auto";

    # Less with raw control chars
    less = "less -r";

    # Human friendly numbers
    df = "df -h";
    du = "du -h -d 2";
  };

  # Abbreviations: shortcuts that expand inline so history shows the full command.
  # For ls/tree variants, we expand to the alias name (e.g. ll -> ls -l)
  # so history reads naturally while the alias handles the eza substitution.
  commonAbbreviations = {
    # PS
    psa = "ps aux";

    # Moving around
    cdb = "cd -";

    # ls variants (expand to aliased ls/tree, not eza directly)
    ll = "ls -l";
    la = "ls -la";
    lt = "ls --tree";
    lg = "ls -l --git";
    lag = "ls -la --git";
    lsg = "ls -l --git --git-ignore";
    lh = "ls -l --header";
    lm = "ls -l --modified";
    lc = "ls -l --created";
    ls-size = "ls -l --sort=size";
    ls-time = "ls -l --sort=modified";
    ls-name = "ls -l --sort=name";
    lsi = "ls -l --icons";
    lai = "ls -la --icons";
    lsf = "ls -l --classify";
    lso = "ls -l --octal-permissions";

    # Tree variants
    tree2 = "tree --level=2";
    tree3 = "tree --level=3";
    treei = "tree --icons";

    # Bat
    b = "bat";

    # Zoxide
    zz = "z -";
    zq = "z -i";
    zl = "zoxide query -l";
    zs = "zoxide query -s";
    zr = "zoxide remove";
    zstats = "zoxide query -l -s";

    # Git
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
    gnb = "git nb";
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

    # Common shell
    tf = "tail -f";
    l = "less";
    cl = "clear";
    c = "clear";

    # Zippin
    gz = "tar -zcvf";

    # Networking
    myip = "curl -s ipinfo.io/ip";

    # Misc
    h = "history";

    # AWS
    awsfed = "aws sso login --sso-session default";
  };

  # Aliases that contain pipes or semicolons (can't be abbreviations)
  commonPipeAliases = {
    psg = "ps aux | grep ";
    lsgrep = "ls -l | grep";
    ports = "lsof -i -P | grep LISTEN";
    zt = "zoxide query -l | tail";
    zc = "zoxide query -l | wc -l";
    zf = "zoxide query -l | fzf";
    zh = "zoxide query -l | head";
  };

  # macOS-only
  darwinAbbreviations = lib.optionalAttrs pkgs.stdenv.isDarwin {
    localip = "ipconfig getifaddr en0";
    flushdns = "sudo dscacheutil -flushcache";
    caff = "caffeinate -d -i -m -s";
  };

  # Linux-only
  linuxAbbreviations = lib.optionalAttrs pkgs.stdenv.isLinux {
    flushdns = "resolvectl flush-caches";
  };

  # Linux-only aliases (contain pipes)
  linuxAliases = lib.optionalAttrs pkgs.stdenv.isLinux {
    localip = "hostname -I | awk '{print $1}'";
  };
in
{
  programs.fish = {
    shellAliases = commonAliases // commonPipeAliases // linuxAliases;
    shellAbbrs = commonAbbreviations // darwinAbbreviations // linuxAbbreviations;
  };
}
