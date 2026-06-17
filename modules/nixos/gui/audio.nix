{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixconfig.gui.audio;
in
{
  options.nixconfig.gui.audio = {
    # On by default with the desktop, mirroring nixconfig.gui.fonts.
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable desktop audio (PipeWire)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Make PipeWire explicit rather than relying on KDE/Plasma to pull it in
    # (a Hyprland-only session won't).
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
      # wireplumber.enable already defaults to true; kept explicit for clarity.
      wireplumber.enable = true;
    };

    # Realtime scheduling for PipeWire (lower latency, fewer xruns).
    security.rtkit.enable = true;

    # The `pactl` client (from pulseaudio) talks to pipewire-pulse. pipewire's
    # pulse.enable provides only the server, not this CLI, and apps that shell
    # out to it (e.g. Vicinae's volume command) fail without it on PATH.
    environment.systemPackages = [ pkgs.pulseaudio ];
  };
}
