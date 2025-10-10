_:
let
  inherit (builtins) readDir attrNames filter;
in
{
  # Virt modules define their own options and enable guards
  imports = map (fn: ./${fn}) (filter (fn: fn != "default.nix") (attrNames (readDir ./.)));
}
