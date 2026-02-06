{
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      blame-palette = "\"#303446 #292c3c #232634 #414559 #51576d\"";
      commit-decoration-style = "\"#737994\" bold box ul";
      dark = true;
      file-decoration-style = "\"#737994\"";
      file-style = "\"#c6d0f5\"";
      hunk-header-decoration-style = "\"#737994\" box ul";
      hunk-header-file-style = "bold";
      hunk-header-line-number-style = "bold \"#a5adce\"";
      hunk-header-style = "file line-number syntax";
      line-numbers = true;
      line-numbers-left-style = "\"#737994\"";
      line-numbers-minus-style = "bold \"#e78284\"";
      line-numbers-plus-style = "bold \"#a6d189\"";
      line-numbers-right-style = "\"#737994\"";
      line-numbers-zero-style = "\"#737994\"";
      minus-emph-style = "bold syntax \"#704f5c\"";
      minus-style = "syntax \"#544452\"";
      navigate = true;
      plus-emph-style = "bold syntax \"#596b5e\"";
      plus-style = "syntax \"#475453\"";
      map-styles = ''
        bold purple => syntax "#66597e", bold blue => syntax "#505d81", bold cyan => syntax "#546b7a", bold yellow => syntax "#6f6860"
      '';
      syntax-theme = "catppuccin-frappe";
    };
  };
}
