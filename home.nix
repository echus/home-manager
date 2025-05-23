{ config, pkgs, minimal-tmux-status, tmux-continuum, ... }:

let
  # See: https://nixos.wiki/wiki/Google_Cloud_SDK
  gdk = pkgs.google-cloud-sdk.withExtraComponents( with pkgs.google-cloud-sdk.components; [
    gke-gcloud-auth-plugin
  ]);
in
{
  home.username = "varvara";
  home.homeDirectory = "/home/varvara";

  # Home Manager backwards-compatibility version
  # DON'T CHANGE unless config is compatible with latest version
  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    # Shell
    oh-my-zsh
    any-nix-shell  # zsh support for nix-shell

    # CLI
    git
    gh
    tig
    silver-searcher
    gdk
    awscli2
    coldsnap  # AWS EBS volume CLI

    # Direnv
    direnv
    nix-direnv

    # Programming
    nodejs_22
    yarn-berry
    python3

    # VSCode
    vscodium
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs = {
    # Let Home Manager install and manage itself
    home-manager.enable = true;

    ssh = {
      enable = true;

      serverAliveInterval = 60;

      # Required to use ancient keys for logging into Bindfit etc
      extraConfig = ''
      Host *
        PubkeyAcceptedKeyTypes=+ssh-rsa
        HostKeyAlgorithms=+ssh-rsa
      '';

      matchBlocks = {
        "bindfit" = {
          hostname = "52.63.104.201";
          user = "webadmin";
          identityFile = "~/development/keys/sm-varvara-key-pair-sydney.pem";
        };
      };
    };

    # zsh
    zsh = {
      enable = true;

      autocd = true;
      dotDir = ".config/zsh";

      enableCompletion = true;

      autosuggestion = {
        enable = true;
      };

      initExtra = ''
        # Initialise any-nix-shell
        any-nix-shell zsh --info-right | source /dev/stdin

        # Add yarn globals to PATH
        export PATH="$PATH:`yarn global bin`"
      '';

      history = {
        size = 10000;
      };

      oh-my-zsh = {
        enable = true;

        plugins = [
          "git"
          "node"
          "npm"
          "extract"
          "z"
          "terraform"
        ];

        theme = "af-magic";
      };
    };

    # Neovim
    neovim = {
      enable = true;

      viAlias = true;
      vimAlias = true;

      plugins = with pkgs.vimPlugins; [
        neovim-sensible
        catppuccin-nvim
        vim-nix
        vim-json
        vim-astro
        vim-terraform
        vim-obsession  # Session saving (for resurrect)
        {
          plugin = nvim-colorizer-lua;
          config = ''
            packadd! nvim-colorizer.lua
            lua require 'colorizer'.setup()
          '';
        }
      ];

      extraConfig = ''
        " Use system clipboard for yank/paste
        set clipboard=unnamedplus

        colorscheme catppuccin-macchiato

        set background=dark
        set termguicolors
      '';
    };

    # direnv & nix-direnv
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # tmux
    tmux = {
      enable = true;

      baseIndex = 1;
      historyLimit = 100000;
      shell = "${pkgs.zsh}/bin/zsh";
      clock24 = true;

      # Fix colours
      terminal = "tmux-256color";

      # Turn on mouse mode
      mouse = true;

      # No delay time for escape key press
      escapeTime = 0;

      # Don't put sensible at top of config
      sensibleOnTop = false;

      # NOTE: Commented out as continuum doesn't work with nixpkgs tmux plugin
      # management. Maybe this will be fixed in the future?

      # plugins = with pkgs.tmuxPlugins; [
      #   sensible  # Sensible defaults
      #   vim-tmux-navigator  # Navigate vim/tmux panes
      #   better-mouse-mode
      #   copycat  # Regex search
      #   {
      #     plugin = resurrect;  # Restore sessions
      #     extraConfig = ''
      #       # Enable nvim session restore w/ vim-obsession
      #       set -g @resurrect-strategy-nvim 'session'
      #     '';
      #   }
      #   {
      #     plugin = continuum;  # Auto-restore sessions
      #     extraConfig = "set -g @continuum-restore 'on'";
      #   }
      #   {
      #     plugin = minimal-tmux-status.packages.${pkgs.system}.default;
      #     extraConfig = ''
      #       set -g @minimal-tmux-justify "centre"
      #       set -g @minimal-tmux-status "top"
      #     '';
      #   }
      # ];

      # NOTE: On new install, you will need to manually install tpm:
      # git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
      # Then prefix + I in tmux to install plugins

      extraConfig = ''
        #
        # Plugins
        #

        # Use Tmux Plugin Manager
        set -g @plugin 'tmux-plugins/tpm'  # Use tmux plugin manager
        set -g @plugin 'tmux-plugins/tmux-sensible'
        set -g @plugin 'tmux-plugins/tmux-resurrect'
        set -g @resurrect-strategy-nvim 'session'  # Enable nvim session restore w/ vim-obsession
        set -g @plugin 'tmux-plugins/tmux-continuum'
        set -g @continuum-restore 'on'  # Enable auto session restore
        set -g @plugin 'niksingh710/minimal-tmux-status'
        set -g @minimal-tmux-justify "centre"
        set -g @minimal-tmux-status "top"
        set -g @plugin 'tmux-plugins/tmux-copycat'  # Regex search

        #
        # Appearance
        #

        # Fix colours
        set -ga terminal-overrides ",*256col*:Tc"

        # Move status bar to top
        set-option -g status-position top

        #
        # Behaviour
        #

        # Renumber windows on window close
        set -g renumber-windows on

        # Automatically set window titles
        set-window-option -g automatic-rename on
        set-option -g set-titles on

        # Monitor window activity
        set -g monitor-activity on

        # Disable copy on mouse release
        unbind -T copy-mode-vi MouseDragEnd1Pane

        # Open new sessions at current path
        bind c new-window -c "#{pane_current_path}"
        bind '"' split-window -c "#{pane_current_path}"
        bind % split-window -h -c "#{pane_current_path}"

        #
        # Key bindings
        #

        # Shift arrow to switch windows
        bind -n S-Left  previous-window
        bind -n S-Right next-window

        # Swap windows
        bind-key S-Left swap-window -t -1
        bind-key S-Right swap-window -t +1

        # Shortcut to reload tmux config
        bind r source-file ~/.config/tmux/tmux.conf

        # Vim style copying
        bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "xsel -i -p && xsel -o -p | xsel -i -b"
        bind-key p run "xsel -o | tmux load-buffer - ; tmux paste-buffer"

        # Window splitting
        bind-key v split-window -h
        bind-key s split-window -v

        # Vim style pane resizing
        bind-key J resize-pane -D 5
        bind-key K resize-pane -U 5
        bind-key H resize-pane -L 5
        bind-key L resize-pane -R 5

        bind-key M-j resize-pane -D
        bind-key M-k resize-pane -U
        bind-key M-h resize-pane -L
        bind-key M-l resize-pane -R

        # Vim style pane selection
        bind h select-pane -L
        bind j select-pane -D 
        bind k select-pane -U
        bind l select-pane -R

        # Use Alt-vim keys without prefix key to switch panes
        bind -n M-h select-pane -L
        bind -n M-j select-pane -D 
        bind -n M-k select-pane -U
        bind -n M-l select-pane -R

        # Use Alt-arrow keys without prefix key to switch panes
        bind -n M-Left select-pane -L
        bind -n M-Right select-pane -R
        bind -n M-Up select-pane -U
        bind -n M-Down select-pane -D

        #
        # Initialise TPM (keep this at the bottom)
        #

        run -b '~/.tmux/plugins/tpm/tpm'
      '';
    };

    vscode = {
      enable = true;

      package = pkgs.vscodium;

      userSettings = {
        "workbench.colorTheme" = "Monokai";
        "files.autoSave" = "afterDelay";

        # Set default terminal to home-manager zsh
        "terminal.integrated.profiles.linux" =  {
          "zsh" = {
            "path" = "/home/varvara/.nix-profile/bin/zsh";
          };
        };

        "terminal.integrated.defaultProfile.linux" = "zsh";

        # Configure vscode-neovim executable and affinity
        "vscode-neovim.neovimExecutablePaths.linux" = "/home/varvara/.nix-profile/bin/nvim";

        "extensions.experimental.affinity" = {
          "asvetliakov.vscode-neovim" = 1;
        };
      };

      extensions = with pkgs.vscode-extensions; [
        asvetliakov.vscode-neovim
        yoavbls.pretty-ts-errors
        bbenoist.nix
        ms-python.python
        ms-azuretools.vscode-docker
      ];
    };
  };
}
