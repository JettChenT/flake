{ pkgs, ... }: {
  home.stateVersion = "25.05";

  # GIT
  programs.git = {
    enable = true;
    userName = "JettChenT";
    userEmail = "jettchen12345@gmail.com";
    aliases = {
      co = "checkout";
      cm = "commit";
      st = "status";
      br = "branch";
      df = "diff";
      lg = "log";
      pl = "pull";
    };
  };

  # FISH
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting
      fish_vi_key_bindings
      fish_add_path ~/.opencode/bin
      fish_add_path "~/.bun/bin"
      fish_add_path ~/.cargo/bin
      fish_add_path ~/.local/bin

      # creds: https://github.com/ryanccn/flake
      function expose_app_to_path
          set -f app $argv[1]

          if test -d "$HOME/Applications/$app.app"
              fish_add_path -P "$HOME/Applications/$app.app/Contents/MacOS"
          end
          if test -d "/Applications/$app.app"
              fish_add_path -P "/Applications/$app.app/Contents/MacOS"
          end
      end

      expose_app_to_path Ghostty
    '';
    plugins = [
      # Enable a plugin (here grc for colorized command output) from nixpkgs
      {
        name = "grc";
        src = pkgs.fishPlugins.grc.src;
      }
    ];
    shellAliases = { j = "just"; };
    shellAbbrs = {
      gp = "git push";
      gpl = "git pull";
    };
  };

  programs.starship = {
    enable = true;
    # Configuration written to ~/.config/starship.toml
    settings = { shell.disabled = false; };
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.atuin = {
    enable = true;
    flags = [ "--disable-up-arrow" ];
    settings = {
      auto_sync = true;
      sync_frequency = "5m";
      sync_address = "https://api.atuin.sh";
      search_mode = "fuzzy";
    };
  };

  home.packages = with pkgs;
    [
      # Add any additional packages you want installed via home-manager
    ];
}
