{ lib, ... }:
{
  # Power management via TuneD instead of power-profiles-daemon. TuneD's ppd
  # compatibility layer (services.tuned.ppdSupport, default true) provides the
  # net.hadess.PowerProfiles D-Bus interface, so KDE powerdevil's profile
  # switcher and Noctalia's power-profile widget keep working unchanged.
  services.tuned.enable = true;

  # plasma6 enables power-profiles-daemon at normal priority; it is mutually
  # exclusive with TuneD (asserted), so force it off.
  services.power-profiles-daemon.enable = lib.mkForce false;

  # Make these explicit rather than relying on KDE to pull them in: Hyprland
  # sessions won't, and tuned.ppdSupport asserts upower is enabled.
  services.upower.enable = true;
  hardware.bluetooth.enable = true;
}
