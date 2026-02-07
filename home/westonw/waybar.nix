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
          "custom/notification"
          "cpu"
          "memory"
          "temperature"
          "disk"
          "pulseaudio"
          "bluetooth"
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
          format = "󰥔 {:%H:%M}";
          format-alt = "󰃭 {:%A, %B %d, %Y}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";
          calendar = {
            mode = "month";
            weeks-pos = "left";
            on-click-right = "mode";
            format = {
              months = "<span color='" + c.base0D + "'><b>{}</b></span>";
              days = "<span color='" + c.base05 + "'>{}</span>";
              weeks = "<span color='" + c.base04 + "'>{}</span>";
              weekdays = "<span color='" + c.base0D + "'>{}</span>";
              today = "<span color='" + c.base08 + "'><b>{}</b></span>";
            };
          };
          on-click = "mode";
        };

        cpu = {
          format = "󰍛 {usage}%";
          interval = 5;
          tooltip = true;
        };

        memory = {
          format = "󰘚 {percentage}%";
          interval = 5;
          tooltip = true;
          tooltip-format = "{used:0.1f}GiB / {total:0.1f}GiB";
        };

        temperature = {
          format = "󰔏 {temperatureC}°C";
          format-critical = "󱃂 {temperatureC}°C";
          critical-threshold = 80;
          interval = 5;
          tooltip = true;
          hwmon-path = "/sys/class/hwmon/hwmon1/temp1_input";
        };

        disk = {
          format = "󰋊 {percentage_used}%";
          path = "/";
          interval = 30;
          tooltip = true;
          tooltip-format = "{used} / {total} ({percentage_used}%)";
        };

        bluetooth = {
          format = "󰂯 {status}";
          format-connected = "󰂯 {device_alias}";
          format-connected-battery = "󰂯 {device_alias} {device_battery_percentage}%";
          format-disabled = "󰂲 off";
          format-off = "󰂲 off";
          interval = 30;
          on-click = "blueman-manager";
          on-click-right = "rfkill toggle bluetooth";
          tooltip-format = "{controller_alias} ({status})";
          tooltip-format-connected = "{controller_alias} (connected to {device_alias})";
          tooltip-format-off = "{controller_alias} (off)";
        };

        "custom/notification" = {
          format = "{} {icon}";
          format-icons = {
            notification = "󰂚";
            none = "󰂛";
            dnd-notification = "󰂛";
            dnd-none = "󰂛";
          };
          return-type = "json";
          exec-if = "which swaync-client";
          exec = "swaync-client -swb";
          on-click = "swaync-client -t -sw";
          on-click-right = "swaync-client -d -sw";
          escape = true;
          restart-interval = 1;
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = "󰖁 muted";
          format-icons = {
            default = [ "󰕿" "󰖀" "󰕾" ];
          };
          on-click = "pavucontrol";
        };

        network = {
          format-wifi = "󰤨 {signalStrength}%";
          format-ethernet = "󰈀 {ipaddr}";
          format-disconnected = "󰤭 offline";
          tooltip-format-wifi = "{essid} ({signalStrength}%)";
          tooltip-format-ethernet = "{ifname}: {ipaddr}/{cidr}";
        };

        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon} {capacity}%";
          format-charging = "󰂄 {capacity}%";
          format-plugged = "󰂄 {capacity}%";
          format-icons = [ "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
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
      #temperature,
      #disk,
      #pulseaudio,
      #bluetooth,
      #network,
      #battery,
      #tray,
      #custom-notification {
        padding: 0 12px;
        margin: 4px 2px;
        border-radius: 10px;
        background: ${rgba "base01" "0.6"};
        color: ${c.base05};
        transition: all 0.2s ease;
      }

      #clock:hover,
      #cpu:hover,
      #memory:hover,
      #temperature:hover,
      #disk:hover,
      #pulseaudio:hover,
      #bluetooth:hover,
      #network:hover,
      #battery:hover,
      #custom-notification:hover {
        background: ${rgba "base0D" "0.15"};
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

      #temperature.critical {
        color: ${c.base08};
        animation: blink 1s linear infinite;
      }

      #disk.warning {
        color: ${c.base09};
      }

      #disk.critical {
        color: ${c.base08};
      }

      #bluetooth.disabled {
        color: ${c.base03};
      }

      #bluetooth.connected {
        color: ${c.base0D};
      }

      #custom-notification {
        color: ${c.base05};
      }

      #custom-notification.notification {
        color: ${c.base0A};
      }

      @keyframes blink {
        to {
          color: ${c.base02};
        }
      }
    '';
  };
}
