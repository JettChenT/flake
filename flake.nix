{
  description = "Jett's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      home-manager,
    }:
    let
      configuration =
        { pkgs, ... }:
        {
          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          environment.systemPackages = with pkgs; [
            vim
            uv
            bun
            nodejs_24
            mprocs
            croc
            cloudflared
            dotenvy
            git
            mitmproxy
            gh
            btop
            starship
            just
            fishPlugins.grc
            grc
            fzf
            zoxide
            ripgrep
            dust
            alt-tab-macos
            git-lfs
            nil
            nixd
            tokei
            go
            rustup
            yazi
            git-filter-repo
            deluge
            pdm
            (llm.withPlugins {
              llm-openrouter = true;
              llm-git = true;
            })
          ];

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";
          nix.enable = false;

          # Enable alternative shell support in nix-darwin.
          programs.fish.enable = true;

          # Set fish as the default shell
          users.knownUsers = [ "jettchen" ];
          users.users.jettchen = {
            name = "jettchen";
            home = "/Users/jettchen";
            uid = 501;
          };

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 6;

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";

          # touchID
          security.pam.services.sudo_local.touchIdAuth = true;

          # Enable home-manager
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.jettchen = import ./home.nix;
          home-manager.backupFileExtension = "backup";
        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#simple
      darwinConfigurations."simple" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          home-manager.darwinModules.home-manager
        ];
      };
    };
}
