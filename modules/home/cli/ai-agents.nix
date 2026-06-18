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
    programs.antigravity-cli = {
      enable = true;
      package = ai.antigravity-cli;
      enableMcpIntegration = true;
    };

    programs.claude-code = {
      enable = true;
      package = ai.claude-code;
      enableMcpIntegration = true;
    };

    programs.codex = {
      enable = true;
      package = ai.codex;
      enableMcpIntegration = true;
      settings = {
        model = "gpt-5.5";
        model_reasoning_effort = "high";
        projects = {
          "${config.home.homeDirectory}/Projects".trust_level = "trusted";
          "${config.home.homeDirectory}/Projects/nix-workstations".trust_level = "trusted";
        };
      };
      context = ''
        # Custom instructions for Codex agents in ~/.codex/AGENTS.md
        # Add your coding guidelines and preferences here
      '';
    };

    programs.github-copilot-cli = {
      enable = true;
      package = ai.copilot-cli;
      enableMcpIntegration = true;
    };

    programs.mcp = {
      enable = true;
      servers.nixos.command = lib.getExe pkgs.mcp-nixos;
    };

    home.packages = [
      ai.openspec
      ai."spec-kit"
      pkgs.mcp-nixos
    ];
  };
}
