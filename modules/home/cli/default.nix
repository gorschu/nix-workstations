_:
let
  inherit (builtins) readDir attrNames filter;
in
{
  # Always import all CLI modules unconditionally
  # Individual modules control themselves via homeconfig.cli.* options
  imports = map (fn: ./${fn}) (filter (fn: fn != "default.nix") (attrNames (readDir ./.)));
}
