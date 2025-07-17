{ pkgs, ... }: {
  home.stateVersion = "25.05";

  # GIT
  programs.git = {
    enable = true;
    userName = "JettChenT";
    userEmail = "jettchen12345@gmail.com";
  };

  # FISH
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting # Disable greeting
    '';
    plugins = [
      # Enable a plugin (here grc for colorized command output) from nixpkgs
      { name = "grc"; src = pkgs.fishPlugins.grc.src; }
    ];
    shellAliases = {
      j = "just";
    };
  };

  programs.starship = {
    enable = true;
    # Configuration written to ~/.config/starship.toml
    settings = {
      shell.disabled = false;
    };
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.atuin = {
    enable = true;
    settings = {
      auto_sync = true;
      sync_frequency = "5m";
      sync_address = "https://api.atuin.sh";
      search_mode = "fuzzy";
    };
  };

  home.packages = with pkgs; [
    # Add any additional packages you want installed via home-manager
  ];
}
