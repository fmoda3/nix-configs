{ pkgs, ... }:
{
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
    };
    extensions = [
      pkgs.gh-contribs
      pkgs.gh-eco
      pkgs.gh-f
      pkgs.gh-notify
    ];
  };

  programs.gh-dash = {
    enable = true;
    settings = {
      prSections = [
        {
          title = "My Pull Requests";
          filters = "is:open author:@me";
          type = null;
        }
        {
          title = "Needs My Review";
          filters = "is:open review-requested:@me";
          type = null;
        }
        {
          title = "Involved";
          filters = "is:open involves:@me -author:@me";
          type = null;
        }
      ];
      issuesSections = [
        {
          title = "My Issues";
          filters = "is:open author:@me";
        }
        {
          title = "Assigned";
          filters = "is:open assignee:@me";
        }
        {
          title = "Involved";
          filters = "is:open involves:@me -author:@me";
        }
      ];
      repo = {
        branchesRefetchIntervalSeconds = 30;
        prsRefetchIntervalSeconds = 60;
      };
      defaults = {
        preview = {
          open = true;
          width = 50;
        };
        prsLimit = 20;
        prApproveComment = "LGTM";
        issuesLimit = 20;
        view = "prs";
        layout = {
          prs = {
            updatedAt = {
              width = 5;
            };
            createdAt = {
              width = 5;
            };
            repo = {
              width = 20;
            };
            author = {
              width = 15;
            };
            authorIcon = {
              hidden = false;
            };
            assignees = {
              width = 20;
              hidden = true;
            };
            base = {
              width = 15;
              hidden = true;
            };
            lines = {
              width = 15;
            };
          };
          issues = {
            updatedAt = {
              width = 5;
            };
            createdAt = {
              width = 5;
            };
            repo = {
              width = 15;
            };
            creator = {
              width = 10;
            };
            creatorIcon = {
              hidden = false;
            };
            assignees = {
              width = 20;
              hidden = true;
            };
          };
        };
        refetchIntervalMinutes = 30;
      };
      keybindings = {
        universal = [ ];
        issues = [ ];
        prs = [ ];
        branches = [ ];
      };
      repoPaths = { };
      theme = {
        colors = {
          text = {
            primary = "#c6d0f5";
            secondary = "#8caaee";
            inverted = "#232634";
            faint = "#b5bfe2";
            warning = "#e5c890";
            success = "#a6d189";
            error = "#e78284";
          };
          background = {
            selected = "#414559";
          };
          border = {
            primary = "#8caaee";
            secondary = "#51576d";
            faint = "#414559";
          };
        };
      };
      pager = {
        diff = "";
      };
      confirmQuit = false;
      showAuthorIcons = true;
      smartFilteringAtLaunch = true;
    };
  };
}
