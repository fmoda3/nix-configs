{ config, pkgs, lib, ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableAutosuggestions = true;
    dotDir = ".config/zsh";

    localVariables = {
      GREP_COLOR = "1;33";
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
    };

    initExtra = ''
      eval "$(direnv hook zsh)"
    '';
  };

  # Zsh prompt
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      format = lib.concatStrings [
        "$username"
        "$hostname"
        "$shlvl"
        "$singularity"
        "$kubernetes"
        "$directory"
        "$vcsh"
        "$git_branch"
        "$git_commit"
        "$git_state"
        "$git_metrics"
        "$git_status"
        "$hg_branch"
        "$docker_context"
        "$package"
        "$cmake"
        "$cobol"
        "$dart"
        "$deno"
        "$dotnet"
        "$elixir"
        "$elm"
        "$erlang"
        "$golang"
        "$helm"
        "$java"
        "$julia"
        "$kotlin"
        "$lua"
        "$nim"
        "$nodejs"
        "$ocaml"
        "$perl"
        "$php"
        "$pulumi"
        "$purescript"
        "$python"
        "$rlang"
        "$red"
        "$ruby"
        "$rust"
        "$scala"
        "$swift"
        "$terraform"
        "$vlang"
        "$vagrant"
        "$zig"
        "$nix_shell"
        "$conda"
        "$memory_usage"
        "$aws"
        "$gcloud"
        "$openstack"
        "$env_var"
        "$crystal"
        "$custom"
        "$cmd_duration"
        "$line_break"
        "$jobs"
        "$battery"
        "$status"
        "$shell"
        "$character"
      ];

      right_format = lib.concatStrings [
        "$time"
      ];

      add_newline = false;

      directory = {
        style = "blue";
      };

      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
        vicmd_symbol = "[❮](green)";
      };

      git_branch = {
        format = "[$branch]($style)";
        style = "bright-black";
      };

      git_status = {
        format = "[[(*$conflicted$untracked$modified$staged$renamed$deleted)](218) ($ahead_behind$stashed)]($style)";
        style = "cyan";
        conflicted = "​";
        untracked = "​";
        modified = "​";
        staged = "​";
        renamed = "​";
        deleted = "​";
        stashed = "";
      };

      git_state = {
        format = "\([$state( $progress_current/$progress_total)]($style)\) ";
        style = "bright-black";
      };

      cmd_duration = {
        format = "[$duration]($style) ";
        style = "yellow";
      };

      time = {
        disabled = false;
        format = "[$time]($style)";
        style = "bright-black";
        use_12hr = true;
      };

      # Symbols
      aws = {
        symbol = " ";
      };
      conda = {
        symbol = " ";
      };
      dart = {
        symbol = " ";
      };
      directory = {
        read_only = " ";
      };
      docker_context = {
        symbol = " ";
      };
      elixir = {
        symbol = " ";
      };
      elm = {
        symbol = " ";
      };
      git_branch = {
        symbol = " ";
      };
      golang = {
        symbol = " ";
      };
      hg_branch = {
        symbol = " ";
      };
      java = {
        symbol = " ";
      };
      julia = {
        symbol = " ";
      };
      memory_usage = {
        symbol = " ";
      };
      nim = {
        symbol = " ";
      };
      nix_shell = {
        symbol = " ";
      };
      package = {
        symbol = " ";
      };
      perl = {
        symbol = " ";
      };
      php = {
        symbol = " ";
      };
      python = {
        symbol = " ";
      };
      ruby = {
        symbol = " ";
      };
      rust = {
        symbol = " ";
      };
      scala = {
        symbol = " ";
      };
      shlvl = {
        symbol = " ";
      };
      swift = {
        symbol = "ﯣ ";
      };

    };
  };
}
