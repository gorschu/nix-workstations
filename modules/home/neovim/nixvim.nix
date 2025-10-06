# Neovim configuration managed using https://github.com/nix-community/nixvim
{ pkgs, ... }:
{
  # Theme
  colorschemes.tokyonight.enable = true;

  extraPlugins = with pkgs.vimPlugins; [
    (pkgs.vimUtils.buildVimPlugin {
      name = "neovim-tips";
      src = pkgs.fetchFromGitHub {
        owner = "saxon1964";
        repo = "neovim-tips";
        rev = "d69e3ecb1d1d04a776ef01e2bca3f0eb8a7c9302";
        hash = "sha256-kHeDyST9eg1KVTHkvtr1WycLZgCKaVVVyQCfpYPykWw=";
      };
      dependencies = [ nui-nvim render-markdown-nvim ];
    })
  ];

  extraConfigLua = ''
    require('neovim_tips').setup({})
  '';

  # Settings
  opts = {
    expandtab = true;
    shiftwidth = 2;
    smartindent = true;
    tabstop = 2;
    number = true;
    clipboard = "unnamedplus";
  };

  # Keymaps
  globals = {
    mapleader = " ";
  };

  plugins = {

    # UI
    web-devicons.enable = true;
    lualine.enable = true;
    bufferline.enable = true;
    treesitter.enable = true;
    which-key = {
      enable = true;
    };
    noice = {
      # WARNING: This is considered experimental feature, but provides nice UX
      enable = true;
      settings.presets = {
        bottom_search = true;
        command_palette = true;
        long_message_to_split = true;
        #inc_rename = false;
        #lsp_doc_border = false;
      };
    };
    telescope = {
      enable = true;
      keymaps = {
        "<leader>ff" = {
          options.desc = "file finder";
          action = "find_files";
        };
        "<leader>fg" = {
          options.desc = "find via grep";
          action = "live_grep";
        };
      };
      extensions = {
        file-browser.enable = true;
      };
    };

    # Dev
    lsp = {
      enable = true;
      servers = {
        hls = {
          enable = true;
          installGhc = false; # Managed by Nix devShell
        };
        marksman.enable = true;
        nil_ls.enable = true;
        rust_analyzer = {
          enable = true;
          installCargo = false;
          installRustc = false;
        };
      };
    };
    lazygit.enable = true;
  };
  keymaps = [
    # Open lazygit within nvim.
    {
      action = "<cmd>LazyGit<CR>";
      key = "<leader>gg";
    }
  ];
}
