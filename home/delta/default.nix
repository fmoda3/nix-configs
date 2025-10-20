{
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
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
      navigate = true;
      plus-emph-style = "syntax bold \"#007800\"";
      plus-style = "syntax \"#004000\"";
      whitespace-error-style = "\"#280050\" reverse";
      zero-style = "syntax";
      syntax-theme = "catppuccin-frappe";
    };
  };
}
