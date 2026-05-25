let
  # Helper para acortar la asignación de keymaps
  keymap = mode: key: action: desc: {
    inherit mode key action desc;
    silent = true;
  };
in {
  programs.nvf = {
    enable = true;

    settings.vim = {
      viAlias = true;
      vimAlias = true;

      keymaps = [
        (keymap "n" "<left>" "<cmd> echo 'Use h to move!!'<CR>" "")
        (keymap "n" "<right>" "<cmd> echo 'Use l to move!!'<CR>" "")
        (keymap "n" "<up>" "<cmd> echo 'Use k to move!!'<CR>" "")
        (keymap "n" "<down>" "<cmd> echo 'Use j to move!!'<CR>" "")
        (keymap "n" "<C-h>" "<C-w><C-h>" "Move focus to the left window")
        (keymap "n" "<C-l>" "<C-w><C-l>" "Move focus to the right window")
        (keymap "n" "<C-k>" "<C-w><C-k>" "Move focus to the up window")
        (keymap "n" "<C-j>" "<C-w><C-j>" "Move focus to the down window")
      ];

      opts = {
        expandtab = true;
        shiftwidth = 0; # Autoindent. Fallback on tabstop.
        tabstop = 2;
        number = true;
        cursorline = true;
      };

      lsp = {
        enable = true;
        formatOnSave = true;

        lspSignature.enable = true;
        trouble.enable = true;
      };

      languages = {
        enableFormat = true;
        enableTreesitter = true;
        enableExtraDiagnostics = true;

        nix.enable = true;
        markdown.enable = true;
        bash.enable = true;
      };

      visuals = {
        nvim-cursorline.enable = true;
        cinnamon-nvim.enable = true;
        fidget-nvim.enable = true;

        highlight-undo.enable = true;
        blink-indent.enable = true;
        indent-blankline.enable = true;
      };

      theme = {
        enable = true;
        name = "catppuccin";
        style = "mocha";
        transparent = false;
        extraConfig = ''
          integrations = {
            lualine = true,
          }
        '';
      };

      statusline.lualine.enable = true;

      autopairs.nvim-autopairs.enable = true;
      autocomplete.nvim-cmp.enable = true;
      snippets.luasnip.enable = true;

      filetree = {
        neo-tree = {
          enable = true;
          setupOpts = {
            # No-nerdfonts setting
            default_component_configs = {
              icon = {
                folder_closed = ">";
                folder_open = "v";
                folder_empty = "~";
                default = "*";
              };

              git_status = {
                symbols = {
                  added = "+";
                  modified = "~";
                  deleted = "-";
                  renamed = "r";
                  untracked = "?";
                  ignored = ".";
                  unstaged = "u";
                  staged = "s";
                  conflict = "!";
                };
              };
            };
          };
        };
      };

      treesitter.context.enable = true;

      binds = {
        whichKey.enable = true;
        cheatsheet.enable = true;
      };

      git = {
        enable = true;
        gitsigns.enable = true;
        gitsigns.codeActions.enable = false; # throws an annoying debug message
      };

      notify.nvim-notify.enable = true;

      utility = {
        diffview-nvim.enable = true;
        motion = {
          hop.enable = true;
          leap.enable = true;
        };
      };

      notes.todo-comments.enable = true;
      terminal.toggleterm.enable = true;

      ui = {
        borders.enable = true;
        noice.enable = true;
        colorizer.enable = true;
        illuminate.enable = true;
        smartcolumn = {
          enable = true;
          setupOpts.custom_colorcolumn.nix = "110";
        };
        fastaction.enable = true;
      };

      comments.comment-nvim.enable = true;
    };
  };
}
