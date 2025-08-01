{
  programs.lazygit = {
    enable = true;
    settings = {
      theme = {
        activeBorderColor = [ "#1e66f5" "bold" ];
        inactiveBorderColor = [ "#6c6f85" ];
        optionsTextColor = [ "#1e66f5" ];
        selectedLineBgColor = [ "#ccd0da" ];
        cherryPickedCommitBgColor = [ "#bcc0cc" ];
        cherryPickedCommitFgColor = [ "#1e66f5" ];
        unstagedChangesColor = [ "#d20f39" ];
        defaultFgColor = [ "#4c4f69" ];
        searchingActiveBorderColor = [ "#df8e1d" ];
      };
      authorColors = {
        "*" = "#7287fd";
      };
    };
  };
}
