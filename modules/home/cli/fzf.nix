{
  config,
  lib,
  ...
}:
let
  cfg = config.homeconfig.cli;

  bat = lib.getExe config.programs.bat.package;
  eza = lib.getExe config.programs.eza.package;
  fd = lib.getExe config.programs.fd.package;

  excludes = [
    ".git"
    "node_modules"
    "__pycache__"
    "target"
    ".venv"
    ".cargo"
  ];

  fdOptions = lib.concatStringsSep " " (
    [ "--follow" ] ++ map (pattern: "--exclude ${lib.escapeShellArg pattern}") excludes
  );
in
{
  config = lib.mkIf (cfg.enable && cfg.shell.enable) {
    catppuccin.fzf.enable = true;

    programs.fzf = {
      enable = true;
      enableBashIntegration = false;
      enableZshIntegration = true;

      defaultOptions = [
        "--height 40%"
        "--tmux bottom,40%"
        "--layout reverse"
        "--border top"
      ];

      defaultCommand = "${fd} --type f --type l --hidden ${fdOptions}";
      fileWidgetCommand = "${fd} ${fdOptions}";
      changeDirWidgetCommand = "${fd} --type d --hidden ${fdOptions}";

      fileWidgetOptions = [
        "--preview '[ -d {} ] && ${eza} -T {} || ${bat} -n --color=always {}'"
        "--bind 'ctrl-/:change-preview-window(down|hidden|)'"
      ];

      changeDirWidgetOptions = [
        "--preview '${eza} -T {}'"
      ];
    };
  };
}
