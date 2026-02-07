{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use the latest kernel - recommended for AI 300 series
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Networking
  networking.hostName = "nullrunner";
  networking.networkmanager.enable = true;

  # Time & Locale
  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

  # Keyboard
  console.keyMap = "dvorak";

  # Graphics
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Load amdgpu early for both GPUs
  hardware.amdgpu.initrd.enable = true;

  # Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Hint Electron apps to use Wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Display manager: greetd + tuigreet (replaces getty autologin)
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";
        user = "greeter";
      };
    };
  };

  # Polkit agent for GUI authentication dialogs
  security.polkit.enable = true;
  systemd.user.services.polkit-agent = {
    description = "Polkit authentication agent";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.lxqt.lxqt-policykit}/bin/lxqt-policykit-agent";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  # Power management
  services.power-profiles-daemon.enable = true;

  # Firmware updates
  services.fwupd.enable = true;

  # Audio
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General.Experimental = true;
  };
  services.blueman.enable = true;

  # User
  users.users.westonw = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "lp"
    ];
  };

  # System packages (user-level packages moved to home-manager)
  environment.systemPackages = with pkgs; [
    git
    jujutsu
    pciutils
    usbutils
  ];

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.space-mono
    noto-fonts
    noto-fonts-color-emoji
  ];

  # ── Stylix Theming ──────────────────────────────────────────────────────────────

  stylix = {
    enable = true;
    polarity = "dark";

    # Catppuccin Mocha color scheme
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

    # Wallpaper (swap by changing the path to any image in ../../wallpapers/)
    image = ../../wallpapers/train-sideview.png;

    # Fonts
    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.space-mono;
        name = "SpaceMono Nerd Font";
      };
      sansSerif = {
        package = pkgs.noto-fonts;
        name = "Noto Sans";
      };
      serif = {
        package = pkgs.noto-fonts;
        name = "Noto Serif";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
      sizes = {
        applications = 12;
        terminal = 13;
        desktop = 11;
        popups = 12;
      };
    };

    # Cursor
    cursor = {
      package = pkgs.catppuccin-cursors.mochaLight;
      name = "catppuccin-mocha-light-cursors";
      size = 24;
    };

    # Opacity (slightly transparent for the polished look)
    opacity = {
      applications = 0.95;
      terminal = 0.9;
      desktop = 0.9;
      popups = 0.95;
    };
  };

  # Nix settings
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Don't change this ever
  system.stateVersion = "25.11";
}
