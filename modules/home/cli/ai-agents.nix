{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.homeconfig.cli;
  ai = pkgs.llm-agents;
in
{
  config = lib.mkIf (cfg.enable && cfg.development.enable) {
    programs.claude-code = {
      enable = true;
      package = ai.claude-code;
    };

    programs.codex = {
      enable = true;
      package = ai.codex;
      settings = { };
      context = ''
        # Custom instructions for Codex agents in ~/.codex/AGENTS.md
        # Add your coding guidelines and preferences here
      '';
    };

    home.packages = with ai; [
      copilot-cli
      gemini-cli
    ];
  };
}
