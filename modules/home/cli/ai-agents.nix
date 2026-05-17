{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.homeconfig.cli;
in
{
  config = lib.mkIf (cfg.enable && cfg.development.enable) {
    programs.claude-code = {
      enable = true;
    };

    programs.codex = {
      enable = true;
      settings = {
        # Codex configuration in ~/.codex/config.yaml
        # Add your preferred settings here
      };
      context = ''
        # Custom instructions for Codex agents in ~/.codex/AGENTS.md
        # Add your coding guidelines and preferences here
      '';
    };

    # GitHub Copilot CLI
    home.packages = with pkgs; [
      copilot-cli
      gemini-cli
    ];
  };
}
