{ config, pkgs, ... }:
{
  programs.claude-code = {
    enable = true;
  };

  programs.codex = {
    enable = true;
    settings = {
      # Codex configuration in ~/.codex/config.yaml
      # Add your preferred settings here
    };
    custom-instructions = ''
      # Custom instructions for Codex agents in ~/.codex/AGENTS.md
      # Add your coding guidelines and preferences here
    '';
  };

  # GitHub Copilot CLI (no home-manager module yet)
  home.packages = with pkgs; [
    github-copilot-cli
  ];
}
