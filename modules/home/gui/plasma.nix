{
  config,
  lib,
  osConfig ? null,
  ...
}:
let
  cfg = config.homeconfig.gui;
  hostName = if osConfig != null then osConfig.networking.hostName else "unknown";
  kittyBin = lib.getExe config.programs.kitty.package;
  onePasswordBin = "/run/current-system/sw/bin/1password";
  defaultLocale = if osConfig != null then osConfig.i18n.defaultLocale else "en_US.UTF-8";
  regionalLocales = if osConfig != null then osConfig.i18n.extraLocaleSettings else { };
  localeFor = category: regionalLocales.${category} or "de_DE.UTF-8";
  plasmaLanguage = lib.removeSuffix ".UTF-8" defaultLocale;
  # Plasma NotificationManager::Settings::PopupPosition enum: TopRight = 3.
  notificationPopupPositionTopRight = 3;
  touchpadsByHost = {
    hephaestus = [
      {
        name = "Synaptics TM3289-002";
        vendorId = "06cb";
        productId = "0000";
        naturalScroll = true;
      }
    ];
  };
in
{
  config = lib.mkIf (cfg.enable && cfg.plasma.enable) {
    programs.plasma = {
      enable = true;
      overrideConfig = true;

      input = {
        keyboard = {
          layouts = [
            {
              layout = "de";
              variant = "nodeadkeys";
            }
          ];
          model = "pc105";
          options = [ "caps:escape" ];
          numlockOnStartup = "on";
          repeatDelay = 250;
          repeatRate = 40;
        };

        touchpads = touchpadsByHost.${hostName} or [ ];
      };

      fonts = {
        general = {
          family = "Adwaita Sans";
          pointSize = 10;
        };
        fixedWidth = {
          family = "Adwaita Mono";
          pointSize = 10;
          fixedPitch = true;
        };
        toolbar = {
          family = "Adwaita Sans";
          pointSize = 10;
        };
        menu = {
          family = "Adwaita Sans";
          pointSize = 10;
        };
        small = {
          family = "Adwaita Sans";
          pointSize = 8;
        };
        windowTitle = {
          family = "Adwaita Sans";
          pointSize = 10;
          weight = "demiBold";
          styleName = "SemiBold";
        };
      };

      kscreenlocker = {
        passwordRequiredDelay = 30;
        timeout = 10;
      };

      kwin = {
        nightLight.enable = true;
        virtualDesktops = {
          number = 2;
          rows = 1;
        };
      };

      powerdevil = {
        AC = {
          dimDisplay.idleTimeout = 600;
          turnOffDisplay = {
            idleTimeout = 1800;
            idleTimeoutWhenLocked = 120;
          };
          powerProfile = "balanced";
          autoSuspend = {
            action = "sleep";
            idleTimeout = 3600;
          };
        };

        battery = {
          displayBrightness = 50;
          dimDisplay.idleTimeout = 300;
          turnOffDisplay = {
            idleTimeout = 600;
            idleTimeoutWhenLocked = 120;
          };
          powerProfile = "balanced";
          autoSuspend = {
            action = "sleep";
            idleTimeout = 1800;
          };
        };

        lowBattery.powerProfile = "powerSaving";
      };

      panels = [
        {
          location = "bottom";
          height = 42;
          hiding = "normalpanel";
          floating = true;
          widgets = [
            "org.kde.plasma.kickoff"
            "org.kde.plasma.pager"
            {
              iconTasks.launchers = [
                "preferred://browser"
                "applications:net.local.terminal.desktop"
                "preferred://filemanager"
              ];
            }
            "org.kde.plasma.marginsseparator"
            "org.kde.plasma.systemtray"
            {
              digitalClock.calendar.showWeekNumbers = true;
            }
            "org.kde.plasma.showdesktop"
          ];
        }
      ];

      krunner.shortcuts.launch = [
        "Meta+Space"
        "Alt+F2"
        "Search"
      ];

      session.sessionRestore.restoreOpenApplicationsOnLogin = "startWithEmptySession";

      window-rules = [
        {
          description = "Application settings for Vuescan";
          match.window-class = {
            value = "vuescan Vuescan";
            type = "exact";
            match-whole = true;
          };
          apply.fsplevel = {
            value = 3;
            apply = "force";
          };
        }
      ];

      shortcuts = {
        "services/net.local.terminal.desktop"._launch = "Meta+Return";
        "services/net.local.1password.desktop"._launch = "Shift+Meta+Space";
        "services/net.local.1password-2.desktop"._launch = "Shift+Meta+P";

        kwin = {
          "Window Close" = [
            "Meta+Q"
            "Alt+F4"
          ];
          "Overview" = [
            "Meta+W"
            "Meta"
          ];
          "Walk Through Windows of Current Application" = "Meta+^";
          "Walk Through Windows of Current Application (Reverse)" = "Meta+Shift+^";
          "Switch Window Left" = "Meta+H";
          "Switch Window Down" = "Meta+J";
          "Switch Window Up" = "Meta+K";
          "Switch Window Right" = "Meta+L";
          "MoveMouseToFocus" = "Meta+Ö";
        };

        plasmashell."manage activities" = "none";
        ksmserver."Lock Session" = [
          "Meta+Shift+L"
          "Screensaver"
        ];
      };

      configFile = {
        "kdeglobals"."KDE".AutomaticLookAndFeel = true;

        "plasma-localerc" = {
          "Formats" = {
            LC_ADDRESS = localeFor "LC_ADDRESS";
            LC_IDENTIFICATION = localeFor "LC_IDENTIFICATION";
            LC_MEASUREMENT = localeFor "LC_MEASUREMENT";
            LC_MONETARY = localeFor "LC_MONETARY";
            LC_NAME = localeFor "LC_NAME";
            LC_NUMERIC = localeFor "LC_NUMERIC";
            LC_PAPER = localeFor "LC_PAPER";
            LC_TELEPHONE = localeFor "LC_TELEPHONE";
            LC_TIME = localeFor "LC_TIME";
          };
          "Translations".LANGUAGE = plasmaLanguage;
        };

        "plasmaparc"."General".RaiseMaximumVolume = true;

        "plasmanotifyrc"."Notifications".PopupPosition = notificationPopupPositionTopRight;

        "kwinrc" = {
          "Effect-overview".GridBorderActivate = 1;
          "Windows".FocusPolicy = "FocusFollowsMouse";
        };

        "baloofilerc"."General" = {
          "exclude folders" =
            "$HOME/go/,$HOME/mail/,$HOME/data/mail/,$HOME/data/projects/,$HOME/data/general/";
          "only basic indexing" = true;
        };

        "kwalletrc"."Wallet" = {
          "Close When Idle" = false;
          "Close on Screensaver" = false;
          "Default Wallet" = "kdewallet";
          Enabled = true;
          "Idle Timeout" = 10;
          "Launch Manager" = true;
          "Leave Manager Open" = false;
          "Leave Open" = true;
          "Prompt on Open" = true;
          "Use One Wallet" = true;
        };
      };
    };

    xdg.desktopEntries = {
      "net.local.terminal" = {
        name = "Terminal";
        exec = "${kittyBin} --single-instance";
        icon = "kitty";
        categories = [ "System" ];
        terminal = false;
      };

      "net.local.1password" = {
        name = "1Password Quick Access";
        exec = "${onePasswordBin} --quick-access";
        icon = "1password";
        categories = [ "Utility" ];
        terminal = false;
      };

      "net.local.1password-2" = {
        name = "1Password";
        exec = "${onePasswordBin} --toggle";
        icon = "1password";
        categories = [ "Utility" ];
        terminal = false;
      };
    };
  };
}
