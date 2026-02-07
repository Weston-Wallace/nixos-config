{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    # Desktop environment (Phase 5)
    ./hyprland.nix
    ./waybar.nix
    ./wofi.nix
    ./mako.nix
    ./hyprlock.nix

    # Editor (Phase 6)
    inputs.nixvim.homeModules.nixvim
    ./nixvim
  ];

  home.username = "westonw";
  home.homeDirectory = "/home/westonw";
  home.stateVersion = "25.11";

  # User packages (moved from system configuration)
  home.packages = with pkgs; [
    # Wayland utilities
    wl-clipboard
    grim
    slurp
    swww
    brightnessctl

    # CLI tools
    btop
    curl
    wget
    unzip

    # Coding agent
    opencode
  ];

  # Shell
  programs.bash = {
    enable = true;
    shellAliases = {
      nrs = "sudo nixos-rebuild switch --flake ~/nixos-config#nullrunner";
    };
  };

  # Git
  programs.git = {
    enable = true;
    settings.user = {
      name = "Weston-Wallace";
      email = "weston.wallace@outlook.com";
    };
  };

  # Ghostty terminal (Stylix handles theming)
  programs.ghostty = {
    enable = true;
    settings = {
      cursor-style = "block";
      cursor-style-blink = false;
      mouse-hide-while-typing = true;
    };
  };

  # Vivaldi Browser
  programs.vivaldi = {
    enable = true;
    commandLineArgs = [
      "--ozone-platform=wayland"
    ];
  };

  # Let home-manager manage itself
  programs.home-manager.enable = true;
}
