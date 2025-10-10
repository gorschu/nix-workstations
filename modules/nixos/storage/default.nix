_:
let
  inherit (builtins) readDir attrNames filter;
in
{
  # Storage modules define their own options and enable guards
  imports = map (fn: ./${fn}) (filter (fn: fn != "default.nix") (attrNames (readDir ./.)));
}
