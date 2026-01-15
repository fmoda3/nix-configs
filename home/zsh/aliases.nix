{
  # PS
  psa = "ps aux";
  psg = "ps aux | grep ";

  # Moving around
  cdb = "cd -";
  mkcd = "mkdir -p $1 && cd $1";
  ".." = "cd ..";
  "..." = "cd ../..";
  "...." = "cd .././..";

  # Replace ls with eza
  ls = "eza";
  ll = "eza -l";
  la = "eza -la";
  lt = "eza --tree";
  lg = "eza -l --git";
  lag = "eza -la --git";
  lsg = "eza -l --git --git-ignore";
  lh = "eza -l --header";
  lm = "eza -l --modified";
  lc = "eza -l --created";
  ls-size = "eza -l --sort=size";
  ls-time = "eza -l --sort=modified";
  ls-name = "eza -l --sort=name";
  lsi = "eza -l --icons";
  lai = "eza -la --icons";
  lsf = "eza -l --classify";
  lso = "eza -l --octal-permissions";

  # Replace tree with eza
  tree = "eza --tree";
  tree2 = "eza --tree --level=2";
  tree3 = "eza --tree --level=3";
  treei = "eza --tree --icons";

  # Bat
  b = "bat";

  # Zoxide
  zz = "z -"; # Go to previous directory
  zq = "z -i"; # Query interactively
  zl = "zoxide query -l"; # List all directories in database
  zs = "zoxide query -s"; # Show frecency scores
  zt = "zoxide query -l | tail"; # Show recently added directories
  zr = "zoxide remove"; # Remove directory from database
  zc = "zoxide query -l | wc -l"; # Count directories in database
  zf = "zoxide query -l | fzf"; # Use fzf to select from all directories
  zh = "zoxide query -l | head"; # Show most frecent directories
  zstats = "zoxide query -l -s"; # Show all directories with scores

  # Show human friendly numbers and colors
  df = "df -h";
  du = "du -h -d 2";

  # show me files matching "ls grep"
  lsgrep = "ll | grep";

  # Grep
  grep = "grep --color=auto";

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
  cl = "clear";

  # Zippin
  gz = "tar -zcvf";

  # RM
  rm = "nocorrect rm"; # Override rm -i alias which makes rm prompt for every action

  # Networking
  myip = "curl -s ipinfo.io/ip";
  localip = "ipconfig getifaddr en0";
  ports = "lsof -i -P | grep LISTEN";
  flushdns = "sudo dscacheutil -flushcache";

  # Misc
  caff = "caffeinate -d -i -m -s"; # Prevents computer from falling asleep
  h = "history";
  c = "clear";
  reload = "source ~/.zshrc";
}
