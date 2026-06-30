{
  config,
  lib,
  osConfig ? null,
  ...
}:
let
  impermanenceEnabled = osConfig != null && (osConfig.nixconfig.storage.impermanence.enable or false);
  persistenceDefault = if osConfig == null then false else impermanenceEnabled;

  relativePath = lib.types.strMatching "^[^/].*";

  directoryEntry = lib.types.submodule (_: {
    options = {
      path = lib.mkOption {
        type = relativePath;
        description = "Relative directory path under the live home directory.";
      };

      reason = lib.mkOption {
        type = lib.types.str;
        description = "Why this directory belongs in the curated safe-haven and backup scope.";
      };
    };
  });

  fileEntry = lib.types.submodule (_: {
    options = {
      path = lib.mkOption {
        type = relativePath;
        description = "Relative file path under the live home directory.";
      };

      reason = lib.mkOption {
        type = lib.types.str;
        description = "Why this file belongs in the curated safe-haven and backup scope.";
      };
    };
  });
in
{
  options.homeconfig.persistence = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = persistenceDefault;
      defaultText = lib.literalExpression ''
        if osConfig != null then osConfig.nixconfig.storage.impermanence.enable else false
      '';
      description = "Enable Home Manager persistence modules.";
    };

    safeHaven = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = config.homeconfig.persistence.enable;
        defaultText = lib.literalExpression "config.homeconfig.persistence.enable";
        description = "Enable curated safe-haven persistence declarations.";
      };

      path = lib.mkOption {
        type = lib.types.strMatching "^/.*";
        default = "/persist/home/${config.me.username}";
        defaultText = lib.literalExpression ''"/persist/home/''${config.me.username}"'';
        description = "Backing path for curated user safe-haven data.";
      };

      directories = lib.mkOption {
        type = lib.types.listOf directoryEntry;
        default = [ ];
        description = "Curated user directories to persist and expose at normal home paths.";
      };

      files = lib.mkOption {
        type = lib.types.listOf fileEntry;
        default = [ ];
        description = "Curated user files to persist and expose at normal home paths.";
      };
    };
  };
}
