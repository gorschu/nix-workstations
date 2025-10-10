{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixconfig.virt.qemuGuest;
in
{
  options.nixconfig.virt.qemuGuest = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable QEMU guest agent and optimizations";
    };
  };

  config = lib.mkIf cfg.enable {
    # QEMU guest agent for VM integration
    services.qemuGuest.enable = true;

    # Spice vdagent for clipboard sharing and display scaling
    services.spice-vdagentd.enable = true;

    # User-level spice-vdagent client for better clipboard/scaling support
    systemd.user.services.spice-vdagent-client = {
      description = "spice-vdagent client";
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.spice-vdagent}/bin/spice-vdagent -x";
        Restart = "on-failure";
        RestartSec = "5";
      };
    };
    systemd.user.services.spice-vdagent-client.enable = lib.mkDefault true;
  };
}
