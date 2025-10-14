{
  config,
  lib,
  ...
}:
let
  cfg = config.homeconfig.gui;
in
{
  config = lib.mkIf cfg.enable {
    # Font configuration with Microsoft font substitutions
    fonts.fontconfig = {
      enable = true;

      # Font substitutions using home-manager's configFile with proper labeling
      configFile = {
        "05-minimum-font-size" = {
          enable = true;
          label = "Enforce minimum font size";
          priority = 5; # Run very early
          text = ''
            <?xml version="1.0"?>
            <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
            <fontconfig>
              <!-- Enforce minimum font size of 10px -->
              <match target="pattern">
                <test name="pixelsize" compare="less" qual="any">
                  <double>10</double>
                </test>
                <edit name="pixelsize" mode="assign">
                  <double>10</double>
                </edit>
              </match>
            </fontconfig>
          '';
        };

        "10-microsoft-font-substitutions" = {
          enable = true;
          label = "Microsoft font substitutions";
          priority = 10; # Run early in the fontconfig stack
          text = ''
            <?xml version="1.0"?>
            <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
            <fontconfig>
              <!-- Replace Verdana with DejaVu Sans (designed as Verdana replacement) -->
              <match target="pattern">
                <test qual="any" name="family">
                  <string>Verdana</string>
                </test>
                <edit name="family" mode="assign" binding="same">
                  <string>DejaVu Sans</string>
                </edit>
              </match>

              <!-- Replace Arial with Liberation Sans -->
              <match target="pattern">
                <test qual="any" name="family">
                  <string>Arial</string>
                </test>
                <edit name="family" mode="assign" binding="same">
                  <string>Liberation Sans</string>
                </edit>
              </match>

              <!-- Replace Times New Roman with Liberation Serif -->
              <match target="pattern">
                <test qual="any" name="family">
                  <string>Times New Roman</string>
                </test>
                <edit name="family" mode="assign" binding="same">
                  <string>Liberation Serif</string>
                </edit>
              </match>

              <!-- Replace Courier New with Liberation Mono -->
              <match target="pattern">
                <test qual="any" name="family">
                  <string>Courier New</string>
                </test>
                <edit name="family" mode="assign" binding="same">
                  <string>Liberation Mono</string>
                </edit>
              </match>

              <!-- Replace Georgia with Gelasio -->
              <match target="pattern">
                <test qual="any" name="family">
                  <string>Georgia</string>
                </test>
                <edit name="family" mode="assign" binding="same">
                  <string>Gelasio</string>
                </edit>
              </match>
            </fontconfig>
          '';
        };
      };
    };
  };
}
