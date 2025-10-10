_:
let
  inherit (builtins) readDir attrNames filter;
in
{
  # Auto-import all browser modules
  # Individual browser modules control themselves via homeconfig.gui.browsers.enable
  imports = map (fn: ./${fn}) (filter (fn: fn != "default.nix") (attrNames (readDir ./.)));
}
