_:
let
  inherit (builtins) readDir attrNames filter;
in
{
  # Import all GUI modules unconditionally
  # They will be controlled via homeconfig.gui.enable and sub-options
  imports = map (fn: ./${fn}) (filter (fn: fn != "default.nix") (attrNames (readDir ./.)));
}
