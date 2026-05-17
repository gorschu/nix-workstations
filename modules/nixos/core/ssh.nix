{ config, lib, ... }:
let
  cfg = config.nixconfig.ssh;
in
{
  options.nixconfig.ssh = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable and configure SSH with security best practices";
    };
    port = lib.mkOption {
      type = lib.types.int;
      default = 22;
      description = "SSH port to listen on";
    };
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      ports = [ cfg.port ];
      settings = {
        # Security settings
        PermitRootLogin = "prohibit-password";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;

        # Modern crypto only
        KexAlgorithms = [
          "curve25519-sha256"
          "curve25519-sha256@libssh.org"
          "diffie-hellman-group16-sha512"
          "diffie-hellman-group18-sha512"
          "sntrup761x25519-sha512@openssh.com"
        ];
        Ciphers = [
          "chacha20-poly1305@openssh.com"
          "aes256-gcm@openssh.com"
          "aes128-gcm@openssh.com"
          "aes256-ctr"
          "aes192-ctr"
          "aes128-ctr"
        ];
        Macs = [
          "hmac-sha2-512-etm@openssh.com"
          "hmac-sha2-256-etm@openssh.com"
          "umac-128-etm@openssh.com"
        ];
      };
    };

    # /etc/ssh must be traversable by all users so OpenSSH can read
    # AuthorizedKeysFile entries — sshd drops to the target user's UID before
    # opening the file, so a 700 directory silently breaks pubkey auth.
    # Private host keys are protected individually at 0600.
    systemd.tmpfiles.rules = [
      "z /etc/ssh 0755 root root - -"
      "z /etc/ssh/ssh_host_* 0600 root root - -"
    ];
  };
}
