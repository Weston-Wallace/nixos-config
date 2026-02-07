{ config, pkgs, lib, ... }:

let
  colors = config.lib.stylix.colors;

  wallpapersDir = "$HOME/nixos-config/wallpapers";

  wallpaperSwitcher = pkgs.writeShellScript "wallpaper-switcher" ''
    set -e
    
    # Define wallpapers with friendly names
    wallpapers="lit-up-sky.png|Night Sky
train-sideview.png|Train Sideview
minimalist-black-hole.png|Black Hole
pixel-car.png|Pixel Car
pixel-galaxy.png|Pixel Galaxy
satellite.png|Satellite
space.png|Deep Space
voyager-17.jpg|Voyager"
    
    # Show selection menu
    choice=$(echo "$wallpapers" | wofi --dmenu --prompt "Select Wallpaper" --insensitive --matching fuzzy --width 400 --height 300 | cut -d'|' -f1)
    
    if [ -n "$choice" ]; then
      # Check if swww-daemon is running, start if not
      if ! pgrep -x "swww-daemon" > /dev/null; then
        swww-daemon &
        sleep 0.5
      fi
      
      # Set the wallpaper with a smooth 60fps transition
      # --transition-fps 60: Higher framerate for smoother animation on 165Hz display
      # --transition-step 45: Lower step value for smoother interpolation (default is 90 for grow)
      # --filter Nearest: Fastest filter for quicker image loading (good for pixel art wallpapers)
      swww img "${wallpapersDir}/$choice" --transition-type grow --transition-pos 0.5,0.5 --transition-duration 0.8 --transition-fps 60 --transition-step 45 --filter Nearest &
      
      # Wait for swww to finish loading and start transition
      wait $!
      
      # Notify success
      notify-send "Wallpaper Changed" "Applied: $(echo "$wallpapers" | grep "^$choice|" | cut -d'|' -f2)" --icon=preferences-desktop-wallpaper --expire-time=3000
    fi
  '';

in
{
  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      # ── Monitors ────────────────────────────────────────────────────────────────
      # Auto-detect (Framework 16 internal + any external)
      monitor = [ ", preferred, auto, 1" ];

      # ── Input ───────────────────────────────────────────────────────────────────
      input = {
        kb_layout = "us";
        kb_variant = "dvorak";
        follow_mouse = 1;
        sensitivity = 0;

        touchpad = {
          natural_scroll = true;
          tap-to-click = true;
          drag_lock = true;
        };
      };

      # ── General ─────────────────────────────────────────────────────────────────
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;

        "col.active_border" = lib.mkForce "rgba(${colors.base07}ee) rgba(${colors.base0D}ee) 45deg";
        "col.inactive_border" = lib.mkForce "rgba(${colors.base03}aa)";

        layout = "dwindle";
        allow_tearing = false;
      };

      # ── Decoration ──────────────────────────────────────────────────────────────
      decoration = {
        rounding = 10;

        blur = {
          enabled = true;
          size = 7;
          passes = 3;
          new_optimizations = true;
          xray = false;
        };

        shadow = {
          enabled = true;
          range = 15;
          render_power = 3;
        };

        dim_inactive = true;
        dim_strength = 0.1;
      };

      # ── Animations ──────────────────────────────────────────────────────────────
      animations = {
        enabled = true;

        bezier = [
          "easeOutQuint, 0.22, 1, 0.36, 1"
          "easeInOutCubic, 0.65, 0, 0.35, 1"
          "linear, 0, 0, 1, 1"
          "almostLinear, 0.5, 0.5, 0.75, 1.0"
          "quick, 0.15, 0, 0.1, 1"
        ];

        animation = [
          "global, 1, 10, default"
          "border, 1, 5.39, easeOutQuint"
          "windows, 1, 4.79, easeOutQuint"
          "windowsIn, 1, 4.1, easeOutQuint, popin 87%"
          "windowsOut, 1, 1.49, linear, popin 87%"
          "fadeIn, 1, 1.73, almostLinear"
          "fadeOut, 1, 1.46, almostLinear"
          "fade, 1, 3.03, quick"
          "layers, 1, 3.81, easeOutQuint"
          "layersIn, 1, 4, easeOutQuint, fade"
          "layersOut, 1, 1.5, linear, fade"
          "fadeLayersIn, 1, 1.79, almostLinear"
          "fadeLayersOut, 1, 1.39, almostLinear"
          "workspaces, 1, 1.94, almostLinear, fade"
          "workspacesIn, 1, 1.21, almostLinear, fade"
          "workspacesOut, 1, 1.94, almostLinear, fade"
        ];
      };

      # ── Layouts ──────────────────────────────────────────────────────────────────
      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      master = {
        new_status = "master";
      };

      # ── Misc ────────────────────────────────────────────────────────────────────
      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        # Enable window swallowing - terminal windows hide when launching GUI apps
        enable_swallow = true;
        swallow_regex = "^(ghostty|alacritty|kitty|foot)$";
      };

      # ── Special Workspaces ──────────────────────────────────────────────────────
      # Scratchpad workspace (dropdown terminal)
      workspace = [ "special:scratchpad, on-created-empty:ghostty" ];

      # ── Variables ───────────────────────────────────────────────────────────────
      "$mod" = "SUPER";
      "$terminal" = "ghostty";
      "$menu" = "wofi --show drun";
      "$wallpaper" = "${wallpaperSwitcher}";

      # ── Keybindings ─────────────────────────────────────────────────────────────
      bind = [
        # Applications
        "$mod, Return, exec, $terminal"
        "$mod, D, exec, $menu"
        "$mod, W, killactive,"
        "$mod SHIFT, E, exit,"

        # Clipboard history picker (Ghostty uses Super+C/V internally)
        "$mod SHIFT, V, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy"

        # Layout
        "$mod, F, fullscreen, 0"
        "$mod, V, togglefloating,"
        "$mod, P, pseudo,"
        "$mod, S, togglesplit,"

        # Focus (vim-style)
        "$mod, H, movefocus, l"
        "$mod, L, movefocus, r"
        "$mod, K, movefocus, u"
        "$mod, J, movefocus, d"

        # Move windows (vim-style)
        "$mod SHIFT, H, movewindow, l"
        "$mod SHIFT, L, movewindow, r"
        "$mod SHIFT, K, movewindow, u"
        "$mod SHIFT, J, movewindow, d"

        # Workspaces
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"

        # Move windows to workspaces
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"

        # Scroll through workspaces
        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up, workspace, e-1"

        # Lock screen
        "$mod, Escape, exec, hyprlock"

        # Wallpaper switcher
        "$mod SHIFT, W, exec, $wallpaper"

        # Screenshot with hyprshot
        # Full screen to file
        ", Print, exec, hyprshot -m output -o ~/Pictures/Screenshots/"
        # Region selection to clipboard
        "SHIFT, Print, exec, hyprshot -m region --clipboard-only"
        # Active window to clipboard
        "CTRL, Print, exec, hyprshot -m window --clipboard-only"
        # Full screen to clipboard
        "CTRL SHIFT, Print, exec, hyprshot -m output --clipboard-only"

        # Scratchpad workspace toggle
        "$mod, grave, togglespecialworkspace, scratchpad"
        # Move window to scratchpad
        "$mod SHIFT, grave, movetoworkspace, special:scratchpad"
      ];

      # Mouse bindings
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      # ── Media Keys (Framework 16 Function Keys) ───────────────────────────────────
      bindel = [
        # F1-F3: Volume controls
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"

        # F4-F6: Media controls
        ", XF86AudioPrev, exec, playerctl previous"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioNext, exec, playerctl next"

        # F7-F8: Brightness controls
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
        ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"

        # F9 (if needed): Mic mute
        # ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
      ];

      # ── Window Rules ────────────────────────────────────────────────────────────
      windowrule = [
        "float on, match:class ^(pavucontrol)$"
        "float on, match:class ^(nm-connection-editor)$"
        "float on, match:class ^(blueman-manager)$"
        "float on, match:class ^(thunar)$ match:title ^(File Operation Progress)$"
        "float on, match:title ^(Open File)$"
        "float on, match:title ^(Save As)$"
        "float on, match:title ^(Confirm to replace files)$"
        "float on, match:title ^(Picture-in-Picture)$"
        "pin on, match:title ^(Picture-in-Picture)$"
      ];

      # ── Autostart ───────────────────────────────────────────────────────────────
      exec-once = [
        "waybar"
        "swaync"
        "swww-daemon"
        "swww img ${config.stylix.image}"
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
        "blueman-applet"
        "hypridle"
      ];
    };
  };
}
