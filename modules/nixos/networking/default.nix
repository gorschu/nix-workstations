_:
let
  inherit (builtins) readDir attrNames filter;
in
{
  # Auto-import all .nix files in this directory except default.nix
  imports = map (fn: ./${fn}) (filter (fn: fn != "default.nix") (attrNames (readDir ./.)));
}
