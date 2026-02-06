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

    # Browser (Phase 7)
    inputs.zen-browser.homeModules.beta
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

  # Kitty terminal (Stylix handles theming)
  programs.kitty = {
    enable = true;
    settings = {
      scrollback_lines = 10000;
      enable_audio_bell = false;
      copy_on_select = "clipboard";
      window_padding_width = 6;
    };
  };

  # Zen Browser
  programs.zen-browser = {
    enable = true;
    policies = {
      DisableAppUpdate = true;
      DisableTelemetry = true;
      DisableFeedbackCommands = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DontCheckDefaultBrowser = true;
      NoDefaultBookmarks = true;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };
    };
  };

  # Let home-manager manage itself
  programs.home-manager.enable = true;
}
