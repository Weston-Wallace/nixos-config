{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    # Desktop environment (Phase 5)
    ./hyprland.nix
    ./waybar.nix
    ./wofi.nix
    ./swaync.nix
    ./hyprlock.nix
    ./spicetify.nix

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
    cliphist
    grim
    slurp
    swww
    brightnessctl
    hyprshot

    # Audio
    pavucontrol
    playerctl

    # Bluetooth
    blueman

    # CLI tools
    btop
    curl
    wget
    unzip
    jq

    # GUI apps
    vesktop

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

  # Disable hyprpaper so swww can manage wallpapers
  services.hyprpaper.enable = lib.mkForce false;

  # Let home-manager manage itself
  programs.home-manager.enable = true;
}
