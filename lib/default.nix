{ lib }:
{
  importNixModules =
    dir:
    let
      entries = builtins.readDir dir;
      isImportable =
        name:
        name != "default.nix"
        && (entries.${name} == "directory" || (entries.${name} == "regular" && lib.hasSuffix ".nix" name));
    in
    map (name: dir + "/${name}") (builtins.filter isImportable (builtins.attrNames entries));
}
