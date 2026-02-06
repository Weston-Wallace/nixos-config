{ config, pkgs, lib, ... }:

let
  colors = config.lib.stylix.colors;
  c = colors.withHashtag;
  fonts = config.stylix.fonts;

  # Helper: build "rgba(r, g, b, a)" from a base16 color name and alpha string
  rgba = color: alpha:
    "rgba(${colors."${color}-rgb-r"}, ${colors."${color}-rgb-g"}, ${colors."${color}-rgb-b"}, ${alpha})";
in
{
  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 35;
        spacing = 8;

        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ "clock" ];
        modules-right = [
          "cpu"
          "memory"
          "pulseaudio"
          "network"
          "battery"
          "tray"
        ];

        "hyprland/workspaces" = {
          format = "{icon}";
          format-icons = {
            "1" = "一";
            "2" = "二";
            "3" = "三";
            "4" = "四";
            "5" = "五";
            "6" = "六";
            "7" = "七";
            "8" = "八";
            "9" = "九";
          };
          on-click = "activate";
          sort-by-number = true;
        };

        clock = {
          format = "  {:%H:%M}";
          format-alt = "  {:%A, %B %d, %Y}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";
        };

        cpu = {
          format = "  {usage}%";
          interval = 5;
          tooltip = true;
        };

        memory = {
          format = "  {percentage}%";
          interval = 5;
          tooltip = true;
          tooltip-format = "{used:0.1f}GiB / {total:0.1f}GiB";
        };

        pulseaudio = {
          format = "{icon}  {volume}%";
          format-muted = "  muted";
          format-icons = {
            default = [ "" "" "" ];
          };
          on-click = "pavucontrol";
        };

        network = {
          format-wifi = "  {signalStrength}%";
          format-ethernet = "  {ipaddr}";
          format-disconnected = "  offline";
          tooltip-format-wifi = "{essid} ({signalStrength}%)";
          tooltip-format-ethernet = "{ifname}: {ipaddr}/{cidr}";
        };

        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon}  {capacity}%";
          format-charging = "  {capacity}%";
          format-plugged = "  {capacity}%";
          format-icons = [ "" "" "" "" "" ];
          tooltip-format = "{timeTo}";
        };

        tray = {
          icon-size = 16;
          spacing = 8;
        };
      };
    };

    # Styling: rounded pill shapes with theme accents
    # Stylix provides the color scheme; we reference it dynamically
    style = lib.mkForce ''
      * {
        font-family: "${fonts.monospace.name}", sans-serif;
        font-size: 13px;
        min-height: 0;
      }

      window#waybar {
        background: ${rgba "base00" "0.85"};
        border-bottom: 2px solid ${rgba "base0D" "0.3"};
      }

      #workspaces button {
        padding: 0 8px;
        margin: 4px 2px;
        border-radius: 10px;
        color: ${c.base05};
        background: transparent;
        transition: all 0.2s ease;
      }

      #workspaces button.active {
        background: ${rgba "base0D" "0.25"};
        color: ${c.base0D};
      }

      #workspaces button:hover {
        background: ${rgba "base0D" "0.15"};
      }

      #clock,
      #cpu,
      #memory,
      #pulseaudio,
      #network,
      #battery,
      #tray {
        padding: 0 12px;
        margin: 4px 2px;
        border-radius: 10px;
        background: ${rgba "base01" "0.6"};
        color: ${c.base05};
      }

      #clock {
        color: ${c.base0D};
        font-weight: bold;
      }

      #battery.warning {
        color: ${c.base09};
      }

      #battery.critical {
        color: ${c.base08};
        animation: blink 1s linear infinite;
      }

      #network.disconnected {
        color: ${c.base03};
      }

      @keyframes blink {
        to {
          color: ${c.base02};
        }
      }
    '';
  };
}
