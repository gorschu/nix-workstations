{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (inputs) self;
  cfg = config.homeconfig.cli;
  cloudCfg = cfg.cloud;

  valueType =
    with lib.types;
    oneOf [
      bool
      int
      float
      str
    ];

  mountDefaults = {
    "vfs-cache-mode" = "full";
    "vfs-cache-max-size" = "5G";
    "vfs-cache-max-age" = "24h";
    "dir-cache-time" = "1h";
    "buffer-size" = "256M";
    "vfs-read-chunk-size" = "32M";
    "vfs-read-chunk-size-limit" = "1G";
    transfers = 8;
    "poll-interval" = "15m";
    retries = 10;
    "low-level-retries" = 20;
    "retries-sleep" = "5s";
    timeout = "30m";
    contimeout = "60s";
  };

  remoteType = lib.types.submodule (
    { name, ... }:
    {
      options = {
        type = lib.mkOption {
          type = lib.types.str;
          description = "rclone backend type, such as drive, dropbox, or webdav.";
        };

        settings = lib.mkOption {
          type = lib.types.attrsOf valueType;
          default = { };
          description = "Static non-secret rclone config values for this remote.";
        };

        secrets = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          description = ''
            Mapping of rclone config keys to keys in the user rclone SOPS file.
            OAuth token values should not be listed here.
          '';
        };

        mount = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether to define and autostart a user rclone mount.";
          };

          path = lib.mkOption {
            type = lib.types.str;
            default = "${config.home.homeDirectory}/Cloud/${name}";
            description = "Local mount point.";
          };

          remotePath = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Path inside the remote to mount.";
          };

          options = lib.mkOption {
            type = lib.types.attrsOf valueType;
            default = { };
            description = "Extra rclone mount command-line options.";
          };
        };
      };
    }
  );

  secretName = remoteName: key: "rclone-${remoteName}-${key}";

  renderValue = value: if lib.isBool value then lib.boolToString value else toString value;

  configArgs =
    settings:
    lib.concatStringsSep " " (
      lib.mapAttrsToList (
        key: value: "${lib.escapeShellArg key} ${lib.escapeShellArg (renderValue value)}"
      ) settings
    );

  secretArgs =
    remoteName: secrets:
    lib.concatStringsSep " " (
      lib.mapAttrsToList (
        key: _:
        "${lib.escapeShellArg key} \"$(${pkgs.coreutils}/bin/cat ${
          lib.escapeShellArg config.sops.secrets.${secretName remoteName key}.path
        })\""
      ) secrets
    );

  mkBootstrapRemote =
    remoteName: remote:
    let
      args = lib.concatStringsSep " " (
        lib.filter (part: part != "") [
          (configArgs remote.settings)
          (secretArgs remoteName remote.secrets)
          "config_refresh_token=false"
        ]
      );
      escapedName = lib.escapeShellArg remoteName;
      escapedType = lib.escapeShellArg remote.type;
    in
    ''
      if ${lib.getExe pkgs.rclone} listremotes | ${pkgs.gnugrep}/bin/grep -qx ${lib.escapeShellArg "${remoteName}:"}; then
        ${lib.getExe pkgs.rclone} config update ${escapedName} ${args} --non-interactive
      else
        ${lib.getExe pkgs.rclone} config create ${escapedName} ${escapedType} ${args} --non-interactive
      fi
    '';

  bootstrapScript = pkgs.writeShellScriptBin "rclone-bootstrap" ''
    ${pkgs.coreutils}/bin/install -d -m700 "$HOME/.config/rclone"
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList mkBootstrapRemote cloudCfg.remotes)}
  '';

  mkMountService =
    remoteName: remote:
    let
      mountPoint = remote.mount.path;
      remoteSpec = "${remoteName}:${remote.mount.remotePath}";
      options = mountDefaults // remote.mount.options;
    in
    lib.nameValuePair "rclone-mount-${remoteName}" {
      Unit = {
        Description = "rclone FUSE mount for ${remoteName}";
        Documentation = "https://rclone.org/commands/rclone_mount/";
        Wants = [ "network-online.target" ];
        After = [
          "network-online.target"
          "rclone-bootstrap.service"
        ];
        Requires = [ "rclone-bootstrap.service" ];
        StartLimitIntervalSec = "10m";
        StartLimitBurst = 5;
      };

      Service = {
        Type = "notify";
        Environment = [
          "PATH=/run/wrappers/bin:/run/current-system/sw/bin:${lib.makeBinPath [ pkgs.fuse3 ]}"
        ];
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg mountPoint}";
        ExecStart = "${lib.getExe pkgs.rclone} mount ${
          lib.cli.toCommandLineShellGNU { } options
        } ${lib.escapeShellArg remoteSpec} ${lib.escapeShellArg mountPoint}";
        ExecStop = "fusermount3 -uz ${lib.escapeShellArg mountPoint}";
        Restart = "always";
        RestartSec = 15;
        RestartSteps = 5;
        RestartMaxDelaySec = "5m";
        StandardOutput = "journal";
        StandardError = "journal";
      };

      Install.WantedBy = [ "default.target" ];
    };

  mountedRemotes = lib.filterAttrs (_: remote: remote.mount.enable) cloudCfg.remotes;
in
{
  options.homeconfig.cli.cloud = {
    sopsFile = lib.mkOption {
      type = lib.types.path;
      default = self + /secrets/users/gorschu/rclone.yaml;
      description = "SOPS file containing static rclone bootstrap secrets.";
    };

    remotes = lib.mkOption {
      type = lib.types.attrsOf remoteType;
      default = { };
      description = "rclone remotes to bootstrap and mount.";
    };
  };

  config = lib.mkIf (cfg.enable && cloudCfg.enable) {
    home.packages = [ pkgs.rclone ];

    sops.secrets = lib.mkMerge (
      lib.flatten (
        lib.mapAttrsToList (
          remoteName: remote:
          lib.mapAttrsToList (key: sopsKey: {
            ${secretName remoteName key} = {
              sopsFile = cloudCfg.sopsFile;
              key = sopsKey;
              mode = "0400";
            };
          }) remote.secrets
        ) cloudCfg.remotes
      )
    );

    systemd.user.tmpfiles.rules = [
      "d %h/.config/rclone 0700 - - -"
      "z %h/.config/rclone/rclone.conf 0600 - - -"
    ]
    ++ lib.mapAttrsToList (_: remote: "d ${remote.mount.path} 0700 - - -") mountedRemotes;

    systemd.user.services = lib.mkMerge [
      {
        rclone-bootstrap = {
          Unit = {
            Description = "Bootstrap static rclone remote configuration";
            After = [ "sops-nix.service" ];
            Requires = [ "sops-nix.service" ];
          };

          Service = {
            Type = "oneshot";
            ExecStart = lib.getExe bootstrapScript;
            Restart = "on-abnormal";
          };

          Install.WantedBy = [ "default.target" ];
        };
      }
      (lib.mapAttrs' mkMountService mountedRemotes)
    ];
  };
}
