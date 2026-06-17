{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.homeconfig.gui;
in
{
  config = lib.mkIf (cfg.enable && cfg.terminals.enable) {
    catppuccin.kitty.enable = true;

    # Ghostty terminal emulator
    programs.ghostty = {
      enable = false;
    };

    programs.kitty = {
      enable = true;
      shellIntegration = {
        mode = "enabled";
        enableBashIntegration = false;
        enableZshIntegration = true;
      };

      settings = {
        font_family = ''family="Iosevka Term" features='+calt +ss14 cv10=4' style=Regular'';
        bold_font = "auto";
        italic_font = "auto";
        bold_italic_font = "auto";
        font_size = 12.0;
        modify_font = "underline_position 2";

        cursor_blink_interval = 1;
        cursor_stop_blinking_after = 15;

        enable_audio_bell = false;
        visual_bell_duration = 0;
        window_alert_on_bell = true;
        bell_on_tab = "🔔 ";

        tab_bar_style = "powerline";
        tab_powerline_style = "slanted";
        active_tab_font_style = "bold";

        hide_window_decorations = false;
        window_padding_width = "2 1 2 1";
        inactive_text_alpha = 0.9;

        show_hyperlink_targets = true;
        strip_trailing_spaces = "smart";

        enabled_layouts = "splits,stack";
        scrollback_lines = 10000;
        allow_remote_control = true;
        listen_on = "unix:@kitty-${config.home.username}";
        wayland_titlebar_color = "background";
      };

      actionAliases = {
        kitty_scrollback_nvim = "kitten ${pkgs.vimPlugins.kitty-scrollback-nvim}/python/kitty_scrollback_nvim.py";
      };

      keybindings = {
        "kitty_mod+h" = "neighboring_window left";
        "kitty_mod+l" = "neighboring_window right";
        "kitty_mod+k" = "neighboring_window up";
        "kitty_mod+j" = "neighboring_window down";

        "kitty_mod+2" = "launch --location=hsplit --cwd=current";
        "kitty_mod+5" = "launch --location=vsplit --cwd=current";

        "kitty_mod+alt+h" = "resize_window narrower";
        "kitty_mod+alt+l" = "resize_window wider";
        "kitty_mod+alt+k" = "resize_window taller";
        "kitty_mod+alt+j" = "resize_window shorter";

        "kitty_mod+f" = "toggle_layout stack";

        "kitty_mod+z" = "scroll_to_prompt -1";
        "kitty_mod+x" = "scroll_to_prompt 1";

        "kitty_mod+enter" = "new_window_with_cwd";
        "kitty_mod+t" = "new_tab_with_cwd";
        "kitty_mod+n" = "new_os_window_with_cwd";

        "kitty_mod+s" = "kitty_scrollback_nvim";
        "kitty_mod+g" = "kitty_scrollback_nvim --config ksb_builtin_last_cmd_output";
      };

      mouseBindings = {
        "left click" = "ungrabbed mouse_handle_click selection prompt";
        "kitty_mod+left click" = "ungrabbed mouse_handle_click link";
        "ctrl+shift+right press" =
          "ungrabbed combine : mouse_select_command_output : kitty_scrollback_nvim --config ksb_builtin_last_visited_cmd_output";
      };

      extraConfig = ''
        # Use additional symbol fonts for Nerd Font, powerline, box drawing, and emoji glyphs.
        symbol_map U+E5FA-U+E6AC Symbols Nerd Font Mono
        symbol_map U+E700-U+E7C5 Symbols Nerd Font Mono
        symbol_map U+F000-U+F2E0 Symbols Nerd Font Mono
        symbol_map U+E200-U+E2A9 Symbols Nerd Font Mono
        symbol_map U+F0001-U+F1AF0 Symbols Nerd Font Mono
        symbol_map U+E300-U+E3E3 Symbols Nerd Font Mono
        symbol_map U+F400-U+F532,U+2665,U+26A1 Symbols Nerd Font Mono
        symbol_map U+E0A0-U+E0A2,U+E0B0-U+E0B3 Symbols Nerd Font Mono
        symbol_map U+E0A3,U+E0B4-U+E0C8,U+E0CA,U+E0CC-U+E0D4 Symbols Nerd Font Mono
        symbol_map U+23FB-U+23FE,U+2B58 Symbols Nerd Font Mono
        symbol_map U+F300-U+F32F Symbols Nerd Font Mono
        symbol_map U+E000-U+E00A Symbols Nerd Font Mono
        symbol_map U+EA60-U+EBEB Symbols Nerd Font Mono
        symbol_map U+E276C-U+E2771 Symbols Nerd Font Mono
        symbol_map U+2500-U+259F Symbols Nerd Font Mono
        symbol_map U+1F600-U+1F64F Noto Color Emoji
      '';
    };

    home.shellAliases = {
      kssh = "kitty +kitten ssh";
    };

  };
}
