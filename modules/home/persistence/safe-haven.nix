{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.homeconfig.persistence;
  safeHaven = cfg.safeHaven;
  homeDirectory = config.home.homeDirectory;
  hasHomePersistence = lib.hasAttrByPath [
    "home"
    "persistence"
  ] options;

  upstreamPersistenceRoot = lib.removeSuffix homeDirectory safeHaven.path;

  allEntries = safeHaven.directories ++ safeHaven.files;
  missingReasons = builtins.filter (entry: entry.reason == "") allEntries;
in
{
  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = !(cfg.enable && safeHaven.enable) || hasHomePersistence;
          message = ''
            homeconfig.persistence.safeHaven requires upstream home.persistence options.
            It is available when Home Manager is embedded in a NixOS system that imports impermanence.
          '';
        }
        {
          assertion = !(cfg.enable && safeHaven.enable) || lib.hasSuffix homeDirectory safeHaven.path;
          message = ''
            homeconfig.persistence.safeHaven.path must end with the Home Manager home directory
            (${homeDirectory}) so upstream impermanence stores data under the requested safe-haven.
          '';
        }
        {
          assertion = !(cfg.enable && safeHaven.enable) || missingReasons == [ ];
          message = "Every homeconfig.persistence.safeHaven entry must have a non-empty reason.";
        }
      ];
    }

    (lib.optionalAttrs hasHomePersistence {
      home.persistence.${upstreamPersistenceRoot} = lib.mkIf (cfg.enable && safeHaven.enable) {
        directories = map (entry: {
          directory = entry.path;
        }) safeHaven.directories;

        files = map (entry: {
          file = entry.path;
        }) safeHaven.files;
      };
    })
  ];
}
