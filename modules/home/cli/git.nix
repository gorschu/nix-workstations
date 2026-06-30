{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.homeconfig.cli;
  hasSigningKey = config.me.gpgSigningKey != null;
  hasSigningPublicKey = config.me.gpgPublicKeyFile != null;
in
{
  config = lib.mkIf (cfg.enable && cfg.development.enable) {
    # https://nixos.asia/en/git
    programs = {
      git = {
        enable = true;
        ignores = [
          "*~"
          "*.swp"
          "**/.claude/settings.local.json"
        ];
        lfs.enable = true;
        signing = lib.mkIf hasSigningKey {
          key = config.me.gpgSigningKey;
          format = "openpgp";
          signByDefault = true;
        };
        settings = {
          alias = {
            ci = "commit";
            dft = "difftool --tool difftastic";
            fixup = "!git log -n 50 --pretty=format:'%h %s' --no-merges | fzf | cut -c -7 | xargs -o git commit --fixup";
            root = "rev-parse --show-toplevel";
            sync = "!git switch main && git pull --prune && git branch --format '%(refname:short) %(upstream:track)' | awk '$2 == \"[gone]\" { print $1 }' | xargs -r git branch -D";
          };
          color.ui = "auto";
          column = {
            branch = "auto";
            status = "never";
            tag = "auto";
            ui = "auto";
          };
          commit.verbose = true;
          core = {
            fsmonitor = true;
            pager = "bat";
            quotepath = false;
            untrackedCache = true;
          };
          credential.helper = "cache --timeout=7200";
          diff = {
            algorithm = "histogram";
            colorMoved = "dimmed-zebra";
            colorMovedWS = "allow-indentation-change";
            tool = "difftastic";
          };
          diff.gpg.textconv = "gpg --no-tty --decrypt";
          difftool = {
            keepBackup = false;
            prompt = false;
          };
          fetch.prune = true;
          feature.manyFiles = true;
          github.user = config.me.username;
          help.autocorrect = 20;
          init.defaultBranch = "main";
          maintenance = {
            auto = true;
            strategy = "incremental";
          };
          merge.conflictStyle = "diff3";
          pager.difftool = "bat";
          pull.rebase = true;
          push.autoSetupRemote = true;
          rebase = {
            autoSquash = true;
            autoStash = true;
            updateRefs = true;
          };
          rerere.enabled = true;
          submodule = {
            fetchJobs = 4;
            recurse = true;
          };
          tag.forceSignAnnotated = true;
          user = {
            name = config.me.fullname;
            email = config.me.email;
          };
        };
      };
      gpg = {
        enable = true;
        publicKeys = lib.optional hasSigningPublicKey {
          source = config.me.gpgPublicKeyFile;
          trust = "ultimate";
        };
      };
    };

    services.gpg-agent = lib.mkIf hasSigningKey {
      enable = true;
      enableZshIntegration = true;
      defaultCacheTtl = 3600;
      maxCacheTtl = 7200;
      grabKeyboardAndMouse = false;
      noAllowExternalCache = true;
      pinentry.package = pkgs.pinentry-qt;
    };
  };
}
