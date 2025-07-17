{ pkgs, ... }: {
  home.stateVersion = "25.05";
  programs.git = {
    enable = true;
    userName = "JettChenT";
    userEmail = "jettchen12345@gmail.com";
  };

  home.packages = with pkgs; [
    # Add any additional packages you want installed via home-manager
  ];
}
