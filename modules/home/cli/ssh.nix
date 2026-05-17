{
  config,
  lib,
  inputs,
  ...
}:
let
  inherit (inputs) self;
  cfg = config.homeconfig.cli;
  sshCfg = config.homeconfig.cli.ssh;
in
{
  options.homeconfig.cli.ssh = {
    secretConfigs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "work"
        "personal"
      ];
      description = "List of SSH config categories to load from encrypted SOPS secrets";
    };

    keys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "id_ed25519_personal"
        "id_ed25519_work"
      ];
      description = "List of SSH private keys to decrypt from SOPS and load into ssh-agent";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.system.enable) {
    # SSH client configuration
    programs.ssh = {
      enable = true;

      # Disable default config - we configure everything explicitly
      enableDefaultConfig = false;

      # Include encrypted config files for different categories (work/personal/etc)
      includes = map (category: "~/.ssh/config.d/${category}") sshCfg.secretConfigs;

      # Match all hosts
      matchBlocks."*" = {
        # Use 1Password SSH agent
        identityAgent = "~/.1password/agent.sock";

        # Connection multiplexing for speed
        controlMaster = "auto";
        controlPath = "~/.ssh/control-%r@%h:%p";
        controlPersist = "30m";

        # Security settings
        hashKnownHosts = true;

        # Performance
        compression = true;

        # Modern crypto
        extraOptions = {
          KexAlgorithms = "curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256";
          Ciphers = "chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com";
          MACs = "hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com";
        };
      };
    };

    # Set SSH_AUTH_SOCK to 1Password agent
    home.sessionVariables = {
      SSH_AUTH_SOCK = "~/.1password/agent.sock";
    };

    # Ensure .ssh directories exist with correct permissions using tmpfiles
    systemd.user.tmpfiles.rules = [
      "d %h/.ssh 0700 - - -"
      "d %h/.ssh/config.d 0700 - - -"
    ];

    # SOPS secrets for SSH configs
    sops.secrets = lib.mkMerge (
      (map (category: {
        "ssh-config-${category}" = {
          sopsFile = self + /secrets/users/gorschu/ssh/${category}.yaml;
          path = "${config.home.homeDirectory}/.ssh/config.d/${category}";
          mode = "0600";
        };
      }) sshCfg.secretConfigs)
      ++ (map (keyName: {
        "ssh-key-${keyName}" = {
          sopsFile = self + /secrets/users/gorschu/ssh/keys/${keyName};
          format = "binary";
          path = "${config.home.homeDirectory}/.ssh/${keyName}";
          mode = "0600";
        };
      }) sshCfg.keys)
    );
  };
}
