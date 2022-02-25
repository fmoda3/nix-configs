{ config, pkgs, ... }:
{
  programs = {
    git = {
      enable = true;

      aliases = {
        # add
        a = "add";                           # add
        chunkyadd = "add --patch";           # stage commits chunk by chunk

        # via http://blog.apiaxle.com/post/handy-git-tips-to-stop-you-getting-fired/
        snapshot = "!git stash save \"snapshot: $(date)\" && git stash apply \"stash@{0}\"";
        snapshots = "!git stash list --grep snapshot";

        #via http://stackoverflow.com/questions/5188320/how-can-i-get-a-list-of-git-branches-ordered-by-most-recent-commit
        recent-branches = "!git for-each-ref --count=5 --sort=-committerdate refs/heads/ --format='%(refname:short)'";

        # branch
        b = "branch -v";                     # branch (verbose)
        create-branch = "!sh -c 'git push origin HEAD:refs/heads/$1 && git fetch origin && git branch --track $1 origin/$1 && cd . && git checkout $1' -";
        delete-branch = "!sh -c 'git push origin :refs/heads/$1 && git remote prune origin && git branch -D $1' -";

        # commit
        c = "commit -m";                     # commit with message
        ca = "commit -am";                   # commit all with message
        ci = "commit";                       # commit
        amend = "commit --amend";            # ammend your last commit
        ammend = "commit --amend";           # ammend your last commit

        # checkout
        co = "checkout";                     # checkout
        nb = "checkout -b";                  # create and switch to a new branch (mnemonic: "git new branch branchname...")

        # cherry-pick
        cp = "cherry-pick -x";               # grab a change from a branch

        # diff
        d = "diff";                          # diff unstaged changes
        dc = "diff --cached";                # diff staged changes
        last = "diff HEAD^";                 # diff last committed change
        diffstat = "diff --stat -r";
  
        # graphviz
        graphviz = "!f() { echo 'digraph git {' ; git log --pretty='format:  %h -> { %p }' \"$@\" | sed 's/[0-9a-f][0-9a-f]*/\"&\"/g' ; echo '}'; }; f";

        # log
        l = "log --graph --date=short";
        llog = "log --date=local";
        lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %Cgreen(%cr) %C(bold blue)<%an>%Creset %s' --abbrev-commit --date=relative";
        changes = "log --pretty=format:\"%h %cr %cn %Cgreen%s%Creset\" --name-status";
        short = "log --pretty=format:\"%h %cr %cn %Cgreen%s%Creset\"";
        changelog = "log --pretty=format:\" * %s\"";
        shortnocolor = "log --pretty=format:\"%h %cr %cn %s\"";
  
        # new
        new = "!sh -c 'git log $1@{1}..$1@{0} \"$@\"'";
  
        # prune
        prune-all = "!git remote | xargs -n 1 git remote prune";

        # pull
        pl = "pull";                         # pull

        # push
        ps = "push";                         # push

        # rebase
        rc = "rebase --continue";            # continue rebase
        rs = "rebase --skip";                # skip rebase

        # remote
        r = "remote -v";                     # show remotes (verbose)

        # reset
        unstage = "reset HEAD";              # remove files from index (tracking)
        uncommit = "reset --soft HEAD^";     # go back before last commit, with files in uncommitted state
        filelog = "log -u";                  # show changes to a file
        mt = "mergetool";                    # fire up the merge tool
  
        # serve the repo
        serve = "!git daemon --reuseaddr --verbose --base-path=. --export-all --informative-errors";

        # stash
        ss = "stash";                        # stash changes
        sl = "stash list";                   # list stashes
        sa = "stash apply";                  # apply stash (restore changes)
        sd = "stash drop";                   # drop stashes (destory changes)

        # status
        s = "status";                        # status
        st = "status";                       # status
        stat = "status";                     # status

        # tag
        t = "tag -n";                        # show tags with <n> lines of each tag message

        # svn helpers
        svnr = "svn rebase";
        svnd = "svn dcommit";
        svnl = "svn log --oneline --show-commit";
  
        # unmerged
        edit-unmerged = "!f() { git ls-files --unmerged | cut -f2 | sort -u ; }; vim `f`";
        add-unmerged = "!f() { git ls-files --unmerged | cut -f2 | sort -u ; }; git add `f`";
  
        # what
        whatis = "show -s --pretty='tformat:%h (%s, %ad)' --date=short";
  
        # who
        who = "shortlog -s --";
        whois = "!sh -c 'git log -i -1 --pretty=\"format:%an <%ae>\n\" --author=\"$1\"' -";
      };

      extraConfig = {
        advice = {
          statusHints = true;
        };

        apply = {
          whitespace = "nowarn";
        };

        branch = {
          autosetupmerge = true;
        };

        color = {
          ui = true;
          status = true;
          interactive = true;
        };

        "color \"branch\"" = {
          current = "yellow reverse";
          local = "yellow";
          remote = "green";
        };

        "color \"diff\"" = {
          meta = "yellow bold";
          frag = "magenta bold";
          old = "red";
          new = "green";
        };

        core = {
          autocrlf = false;
          editor = "vim";
        };

        diff = {
          mnemonicprefix = true;
          algorithm = "patience";
        };

        format = {
          pretty = "format:%C(blue)%ad%Creset %C(yellow)%h%C(green)%d%Creset %C(blue)%s %C(magenta) [%an]%Creset";
        };

        merge = {
          conflictstyle = "diff3";
          summary = true;
          verbosity = 1;
        };

        mergetool = {
          prompt = false;
        };

        pull = {
          ff = "only";
        };

        push = {
          default = "tracking";
        };

        rerere = {
          enabled = true;
        };
      };

      delta = {
        enable = true;
        options = {
          commit-decoration-style = "bold box ul";
          dark = true;
          file-decoration-style = "none";
          file-style = "omit";
          hunk-header-decoration-style = "\"#88C0D0\" box ul";
          hunk-header-file-style = "white";
          hunk-header-line-number-style = "bold \"#5E81AC\"";
          hunk-header-style = "file line-number syntax";
          line-numbers = true;
          line-numbers-left-style = "\"#88C0D0\"";
          line-numbers-minus-style = "\"#BF616A\"";
          line-numbers-plus-style = "\"#A3BE8C\"";
          line-numbers-right-style = "\"#88C0D0\"";
          line-numbers-zero-style = "white";
          minus-emph-style = "syntax bold \"#780000\"";
          minus-style = "syntax \"#400000\"";
          plus-emph-style = "syntax bold \"#007800\"";
          plus-style = "syntax \"#004000\"";
          whitespace-error-style = "\"#280050\" reverse";
          zero-style = "syntax";
          syntax-theme = "Nord";
        };
      };

      ignores = [
        # macOS
        ".DS_Store"
        "._*"
        ".Spotlight-V100"
        ".Trashes"

        # Windows
        "Thumbs.db"
        "Desktop.ini"
      ];
    };
  };

}
