{ config, pkgs, lib, ... }:
with lib;
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    dotDir = ".config/zsh";

    historySubstringSearch.enable = true;
    history = {
      expireDuplicatesFirst = true;
      extended = true;
      findNoDups = true;
      ignoreAllDups = true;
      saveNoDups = true;
    };

    sessionVariables = {
      # Colors
      GREP_COLOR = "38;2;202;158;230";
      GREP_COLORS = "ms=38;2;202;158;230:mc=38;2;166;209;137:fn=38;2;153;209;219:ln=38;2;229;200;144:bn=38;2;186;187;241:se=38;2;129;200;190";
      LS_COLORS = "di=38;2;140;170;238:ln=38;2;166;209;137:ex=38;2;231;130;132:*.tar=38;2;202;158;230:*.zip=38;2;202;158;230:*.gz=38;2;202;158;230:*.bz2=38;2;202;158;230:*.7z=38;2;202;158;230:*.rar=38;2;202;158;230:*.jpg=38;2;229;200;144:*.jpeg=38;2;229;200;144:*.png=38;2;229;200;144:*.gif=38;2;229;200;144:*.bmp=38;2;229;200;144:*.svg=38;2;229;200;144:*.mp4=38;2;239;159;118:*.mkv=38;2;239;159;118:*.avi=38;2;239;159;118:*.mov=38;2;239;159;118:*.webm=38;2;239;159;118:*.mp3=38;2;166;209;137:*.flac=38;2;166;209;137:*.wav=38;2;166;209;137:*.ogg=38;2;166;209;137:*.pdf=38;2;231;130;132:*.doc=38;2;231;130;132:*.txt=38;2;198;208;245";
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
      PAGER = "bat --style=plain --paging=always";
      # Common variables
      ANTHROPIC_API_KEY = ''$(${pkgs.coreutils}/bin/cat ${config.age.secrets."anthropic_ai_key".path})'';
      OPENROUTER_API_KEY = ''$(${pkgs.coreutils}/bin/cat ${config.age.secrets."openrouter_key".path})'';
    } // optionalAttrs (!config.my-home.isWork) {
      GITHUB_PERSONAL_ACCESS_TOKEN = ''$(${pkgs.coreutils}/bin/cat ${config.age.secrets."personal_github_key".path})'';
    } // optionalAttrs config.my-home.isWork {
      # Work-specific variables
      TOAST_GIT = "/Users/frank/Development";
      DOCKER_HOST = "unix:///Users/frank/.colima/default/docker.sock";
      TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE = "/var/run/docker.sock";
      FLAGGY_TOKEN = ''$(${pkgs.coreutils}/bin/cat ${config.age.secrets."flaggy_token".path})'';
      BRAID_PULSAR_MDC_PROPAGATION_KEYS = "Toast-Braid-Route,Toast-Braid-Services";
    };

    shellAliases = {
      # PS
      psa = "ps aux";
      psg = "ps aux | grep ";

      # Moving around
      cdb = "cd -";
      mkcd = "mkdir -p $1 && cd $1";
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd .././..";

      # Show human friendly numbers and colors
      df = "df -h";
      ll = "ls --color=auto -alGh";
      ls = "ls --color=auto -Gh";
      du = "du -h -d 2";

      # show me files matching "ls grep"
      lsg = "ll | grep";

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
      lh = "ls -alt | head"; # see the last modified files
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
    };

    shellGlobalAliases = {
      "--help" = "--help 2>&1 | bat --language=help --style=plain";
    };

    initContent = ''
      eval "$(direnv hook zsh)"
      path+="/opt/homebrew/bin"

      source ${pkgs.catppuccin.zsh-syntax-highlighting}/themes/catppuccin_frappe-zsh-syntax-highlighting.zsh

      setopt BANG_HIST
      setopt HIST_VERIFY

      setopt COMPLETE_IN_WORD     # Complete from both ends of a word.
      setopt ALWAYS_TO_END        # Move cursor to the end of a completed word.
      setopt PATH_DIRS            # Perform path search even on command names with slashes.
      setopt AUTO_MENU            # Show completion menu on a successive tab press.
      setopt AUTO_LIST            # Automatically list choices on ambiguous completion.
      setopt AUTO_PARAM_SLASH     # If completed parameter is a directory, add a trailing slash.
      setopt EXTENDED_GLOB        # Needed for file modification glob modifiers with compinit.
      unsetopt MENU_COMPLETE      # Do not autoselect the first completion entry.
      unsetopt FLOW_CONTROL       # Disable start/stop characters in shell editor.
      unsetopt CASE_GLOB

      # Defaults.
      zstyle ':completion:*:default' list-colors ''${(s.:.)LS_COLORS}
      zstyle ':completion:*:default' list-prompt '%S%M matches%s'

      # Use caching to make completion for commands such as dpkg and apt usable.
      zstyle ':completion::complete:*' use-cache on
      zstyle ':completion::complete:*' cache-path "''${XDG_CACHE_HOME:-$HOME/.cache}/zcompcache"
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

      # Group matches and describe.
      zstyle ':completion:*:*:*:*:*' menu select
      zstyle ':completion:*:matches' group 'yes'
      zstyle ':completion:*:options' description 'yes'
      zstyle ':completion:*:options' auto-description '%d'
      zstyle ':completion:*:corrections' format ' %F{green}-- %d (errors: %e) --%f'
      zstyle ':completion:*:descriptions' format ' %F{yellow}-- %d --%f'
      zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
      zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
      zstyle ':completion:*' format ' %F{yellow}-- %d --%f'
      zstyle ':completion:*' group-name ""
      zstyle ':completion:*' verbose yes

      # Fuzzy match mistyped completions.
      zstyle ':completion:*' completer _complete _match _approximate
      zstyle ':completion:*:match:*' original only
      zstyle ':completion:*:approximate:*' max-errors 1 numeric

      # Increase the number of errors based on the length of the typed word. But make
      # sure to cap (at 7) the max-errors to avoid hanging.
      zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3>7?7:($#PREFIX+$#SUFFIX)/3))numeric)'

      # Don't complete unavailable commands.
      zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'

      # Array completion element sorting.
      zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

      # Directories
      zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories
      zstyle ':completion:*:*:cd:*:directory-stack' menu yes select
      zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'users' 'expand'
      zstyle ':completion:*' squeeze-slashes true

      # History
      zstyle ':completion:*:history-words' stop yes
      zstyle ':completion:*:history-words' remove-all-dups yes
      zstyle ':completion:*:history-words' list false
      zstyle ':completion:*:history-words' menu yes

      # Environment Variables
      zstyle ':completion::*:(-command-|export):*' fake-parameters ''${''${''${_comps[(I)-value-*]#*,}%%,*}:#-*-}

      # Populate hostname completion. But allow ignoring custom entries from static
      # */etc/hosts* which might be uninteresting.
      zstyle -a ':prezto:module:completion:*:hosts' etc-host-ignores '_etc_host_ignores'

      zstyle -e ':completion:*:hosts' hosts 'reply=(
        ''${=''${=''${=''${''${(f)"$(cat {/etc/ssh/ssh_,~/.ssh/}known_hosts(|2)(N) 2> /dev/null)"}%%[#| ]*}//\]:[0-9]*/ }//,/ }//\[/ }
        ''${=''${(f)"$(cat /etc/hosts(|)(N) <<(ypcat hosts 2> /dev/null))"}%%(\#''${_etc_host_ignores:+|''${(j:|:)~_etc_host_ignores}})*}
        ''${=''${''${''${''${(@M)''${(f)"$(cat ~/.ssh/config 2> /dev/null)"}:#Host *}#Host }:#*\**}:#*\?*}}
      )'

      # Don't complete uninteresting users...
      zstyle ':completion:*:*:*:users' ignored-patterns \
        adm amanda apache avahi beaglidx bin cacti canna clamav daemon \
        dbus distcache dovecot fax ftp games gdm gkrellmd gopher \
        hacluster haldaemon halt hsqldb ident junkbust ldap lp mail \
        mailman mailnull mldonkey mysql nagios \
        named netdump news nfsnobody nobody nscd ntp nut nx openvpn \
        operator pcap postfix postgres privoxy pulse pvm quagga radvd \
        rpc rpcuser rpm shutdown squid sshd sync uucp vcsa xfs '_*'

      # ... unless we really want to.
      zstyle '*' single-ignored show

      # Ignore multiple entries.
      zstyle ':completion:*:(rm|kill|diff):*' ignore-line other
      zstyle ':completion:*:rm:*' file-patterns '*:all-files'

      # Kill
      zstyle ':completion:*:*:*:*:processes' command 'ps -u $LOGNAME -o pid,user,command -w'
      zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;36=0=01'
      zstyle ':completion:*:*:kill:*' menu yes select
      zstyle ':completion:*:*:kill:*' force-list always
      zstyle ':completion:*:*:kill:*' insert-ids single

      # Man
      zstyle ':completion:*:manuals' separate-sections true
      zstyle ':completion:*:manuals.(^1*)' insert-sections true

      # Media Players
      zstyle ':completion:*:*:mpg123:*' file-patterns '*.(mp3|MP3):mp3\ files *(-/):directories'
      zstyle ':completion:*:*:mpg321:*' file-patterns '*.(mp3|MP3):mp3\ files *(-/):directories'
      zstyle ':completion:*:*:ogg123:*' file-patterns '*.(ogg|OGG|flac):ogg\ files *(-/):directories'
      zstyle ':completion:*:*:mocp:*' file-patterns '*.(wav|WAV|mp3|MP3|ogg|OGG|flac):ogg\ files *(-/):directories'

      # Mutt
      if [[ -s "$HOME/.mutt/aliases" ]]; then
        zstyle ':completion:*:*:mutt:*' menu yes select
        zstyle ':completion:*:mutt:*' users ''${''${''${(f)"$(<"$HOME/.mutt/aliases")"}#alias[[:space:]]}%%[[:space:]]*}
      fi

      # SSH/SCP/RSYNC
      zstyle ':completion:*:(ssh|scp|rsync):*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
      zstyle ':completion:*:(scp|rsync):*' group-order users files all-files hosts-domain hosts-host hosts-ipaddr
      zstyle ':completion:*:ssh:*' group-order users hosts-domain hosts-host users hosts-ipaddr
      zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
      zstyle ':completion:*:(ssh|scp|rsync):*:hosts-domain' ignored-patterns '<->.<->.<->.<->' '^[-[:alnum:]]##(.[-[:alnum:]]##)##' '*@*'
      zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'
    '';
  };
}
