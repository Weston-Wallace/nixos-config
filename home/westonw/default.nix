{ config, pkgs, lib, inputs, ... }:

let
  godotWayland = pkgs.symlinkJoin {
    name = "godot-wayland";
    paths = [ pkgs.godot ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/godot4 \
        --set SDL_VIDEODRIVER wayland \
        --add-flags "--display-driver wayland"
    '';
  };
in
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

    # WiFi management GUI
    networkmanagerapplet

    # CLI tools
    btop
    curl
    wget
    unzip
    jq
    godotWayland

    # GUI apps
    vesktop
    blender

    # Coding agent
    opencode
  ];

  xdg.desktopEntries."org.godotengine.Godot4.6" = {
    name = "Godot Engine 4.6";
    genericName = "Libre game engine";
    comment = "Multi-platform 2D and 3D game engine with a feature-rich editor";
    exec = "godot4 --display-driver wayland %f";
    icon = "godot";
    terminal = false;
    type = "Application";
    mimeType = [ "application/x-godot-project" ];
    categories = [ "Development" "IDE" ];
  };

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
      background-opacity = "0.85";
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
