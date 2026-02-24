{ config, pkgs, lib, ... }:

let
  colors = config.lib.stylix.colors;
  c = colors.withHashtag;
  fonts = config.stylix.fonts;

  # Helper: build "rgba(r, g, b, a)" from a base16 color name and alpha string
  rgba = color: alpha:
    "rgba(${colors."${color}-rgb-r"}, ${colors."${color}-rgb-g"}, ${colors."${color}-rgb-b"}, ${alpha})";

  networkMenu = pkgs.writeShellScriptBin "waybar-network-menu" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail

    nmcli="${pkgs.networkmanager}/bin/nmcli"
    wofi="${pkgs.wofi}/bin/wofi"

    signal_icon() {
      local signal="$1"
      if (( signal >= 80 )); then
        printf "󰤨"
      elif (( signal >= 60 )); then
        printf "󰤥"
      elif (( signal >= 40 )); then
        printf "󰤢"
      elif (( signal >= 20 )); then
        printf "󰤟"
      else
        printf "󰤯"
      fi
    }

    truncate_text() {
      local text="$1"
      local max="$2"
      if (( ''${#text} > max )); then
        printf "%s…" "''${text:0:max-1}"
      else
        printf "%s" "$text"
      fi
    }

    network_row() {
      local marker="$1"
      local icon="$2"
      local ssid="$3"
      local signal="$4"
      local lock="$5"
      local ssid_short

      ssid_short="$(truncate_text "$ssid" 28)"
      printf "%s%s  %-30s %3s%%%s" "$marker" "$icon" "$ssid_short" "$signal" "$lock"
    }

    if [[ "''${1:-}" == "--status" ]]; then
      wifi_state="$($nmcli -t -f WIFI general 2>/dev/null || true)"
      if [[ "$wifi_state" == "enabled" ]]; then
        active="$($nmcli -t -f IN-USE,SSID,SIGNAL dev wifi list --rescan no 2>/dev/null | ${pkgs.gawk}/bin/awk -F: '$1=="*"{print $2":"$3; exit}')"
        if [[ -n "$active" ]]; then
          signal="''${active##*:}"
          printf "%s %s%%\n" "$(signal_icon "$signal")" "$signal"
        else
          printf "󰤨 on\n"
        fi
      else
        printf "󰤮 off\n"
      fi
      exit 0
    fi

    while true; do
      declare -A ssid_by_key
      declare -A secure_by_key
      entries=()
      connected_rows=()
      sortable_rows=()

      wifi_state="$($nmcli -t -f WIFI general 2>/dev/null || true)"
      if [[ "$wifi_state" == "enabled" ]]; then
        entries+=("A|󰖪  Turn Wi-Fi off")
      else
        entries+=("A|󰖩  Turn Wi-Fi on")
      fi
      entries+=("B|󰤭  Disconnect current Wi-Fi")
      entries+=("R|󰑐  Refresh network list")
      entries+=("T|󰆍  Open nmtui")

      i=1
      while IFS=: read -r active ssid signal security; do
        [[ -z "$ssid" ]] && continue
        signal="''${signal:-0}"
        key="N$i"
        lock=""
        marker="  "
        row=""

        if [[ "$active" == "yes" || "$active" == "*" ]]; then
          marker="● "
        fi
        if [[ -n "$security" && "$security" != "--" ]]; then
          lock=" 󰌾"
          secure_by_key["$key"]="1"
        else
          lock=""
          secure_by_key["$key"]="0"
        fi

        row="$key|$(network_row "$marker" "$(signal_icon "$signal")" "$ssid" "$signal" "$lock")"
        if [[ "$active" == "yes" || "$active" == "*" ]]; then
          connected_rows+=("$row")
        else
          sortable_rows+=("$(printf '%03d' "$signal")|$row")
        fi

        ssid_by_key["$key"]="$ssid"
        i=$((i + 1))
      done < <($nmcli -t -f ACTIVE,SSID,SIGNAL,SECURITY dev wifi list --rescan no 2>/dev/null)

      if (( ''${#connected_rows[@]} > 0 )); then
        entries+=("''${connected_rows[@]}")
      fi

      if (( ''${#sortable_rows[@]} > 0 )); then
        while IFS= read -r sortable; do
          [[ -z "$sortable" ]] && continue
          entries+=("''${sortable#*|}")
        done < <(printf '%s\n' "''${sortable_rows[@]}" | ${pkgs.coreutils}/bin/sort -t'|' -k1,1nr)
      elif [[ "$wifi_state" == "enabled" ]]; then
        entries+=("X|󰤫  Scanning... choose Refresh in a moment")
      fi

      choice="$(printf '%s\n' "''${entries[@]}" | $wofi --dmenu --prompt 'Wi-Fi')" || exit 0
      key="''${choice%%|*}"

      case "$key" in
        A)
          if [[ "$wifi_state" == "enabled" ]]; then
            $nmcli radio wifi off >/dev/null 2>&1 || true
          else
            $nmcli radio wifi on >/dev/null 2>&1 || true
          fi
          ;;
        B)
          device="$($nmcli -t -f DEVICE,TYPE,STATE dev 2>/dev/null | ${pkgs.gawk}/bin/awk -F: '$2=="wifi" && $3=="connected"{print $1; exit}')"
          if [[ -n "$device" ]]; then
            $nmcli dev disconnect "$device" >/dev/null 2>&1 || true
          fi
          ;;
        R)
          (
            printf '%s\n' "󰤨  Refreshing Wi-Fi networks..."
          ) | $wofi --dmenu --prompt 'Wi-Fi' >/dev/null 2>&1 &
          loading_pid=$!

          $nmcli --wait 15 dev wifi rescan >/dev/null 2>&1 || true

          kill "$loading_pid" >/dev/null 2>&1 || true
          wait "$loading_pid" 2>/dev/null || true
          continue
          ;;
        T)
          ${pkgs.ghostty}/bin/ghostty -e ${pkgs.networkmanager}/bin/nmtui >/dev/null 2>&1 &
          ;;
        N*)
          ssid="''${ssid_by_key[$key]:-}"
          [[ -z "$ssid" ]] && continue

          if [[ "''${secure_by_key[$key]:-0}" == "1" ]]; then
            connected=0
            while true; do
              password="$($wofi --dmenu --password --prompt "Password for $ssid" <<< "")" || break
              [[ -z "$password" ]] && break

              if $nmcli dev wifi connect "$ssid" password "$password" >/dev/null 2>&1; then
                connected=1
                break
              fi

              retry_choice="$(printf '%s\n' "R|󰜉  Retry password" "C|󰅖  Cancel" | $wofi --dmenu --prompt "Failed: $ssid")" || break
              retry_key="''${retry_choice%%|*}"
              if [[ "$retry_key" != "R" ]]; then
                break
              fi
            done

            if [[ "$connected" == "1" ]]; then
              exit 0
            fi
            continue
          fi

          if $nmcli dev wifi connect "$ssid" >/dev/null 2>&1; then
            exit 0
          fi

          printf '%s\n' "R|󰑐  Retry connect" "M|󰍺  Back to list" | $wofi --dmenu --prompt "Could not connect to $ssid" >/dev/null || true
          continue
          ;;
        X)
          continue
          ;;
        *)
          exit 0
          ;;
      esac

      exit 0
    done
  '';

  bluetoothMenu = pkgs.writeShellScriptBin "waybar-bluetooth-menu" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail

    btctl="${pkgs.bluez}/bin/bluetoothctl"
    wofi="${pkgs.wofi}/bin/wofi"

    truncate_text() {
      local text="$1"
      local max="$2"
      if (( ''${#text} > max )); then
        printf "%s…" "''${text:0:max-1}"
      else
        printf "%s" "$text"
      fi
    }

    bt_row() {
      local connected_marker="$1"
      local icon="$2"
      local name="$3"
      local name_short

      name_short="$(truncate_text "$name" 34)"
      printf "%s %s  %-36s" "$connected_marker" "$icon" "$name_short"
    }

    if [[ "''${1:-}" == "--status" ]]; then
      powered="$($btctl show 2>/dev/null | ${pkgs.gawk}/bin/awk '/Powered:/ {print $2}')"
      if [[ "$powered" != "yes" ]]; then
        printf "󰂲 off\n"
        exit 0
      fi

      first_connected="$($btctl devices Connected 2>/dev/null | ${pkgs.gawk}/bin/awk 'NR==1{$1="";$2="";sub(/^  */, ""); print; exit}')"
      if [[ -n "$first_connected" ]]; then
        printf "󰂱 %s\n" "$first_connected"
      else
        printf "󰂯 on\n"
      fi
      exit 0
    fi

    declare -A mac_by_key
    entries=()

    powered="$($btctl show 2>/dev/null | ${pkgs.gawk}/bin/awk '/Powered:/ {print $2}')"
    if [[ "$powered" == "yes" ]]; then
      entries+=("A|󰂲  Turn Bluetooth off")
      entries+=("B|󰐍  Scan and pair new device")
    else
      entries+=("A|󰂯  Turn Bluetooth on")
    fi

    i=1
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      mac="$(printf '%s\n' "$line" | ${pkgs.gawk}/bin/awk '{print $2}')"
      name="$(printf '%s\n' "$line" | ${pkgs.gawk}/bin/awk '{$1="";$2="";sub(/^  */, ""); print}')"
      info="$($btctl info "$mac" 2>/dev/null || true)"
      connected="$(printf '%s\n' "$info" | ${pkgs.gawk}/bin/awk '/Connected:/ {print $2}')"

      key="D$i"
      if [[ "$connected" == "yes" ]]; then
        entries+=("$key|$(bt_row "●" "󰂱" "$name")")
      else
        entries+=("$key|$(bt_row " " "󰂯" "$name")")
      fi
      mac_by_key["$key"]="$mac"
      i=$((i + 1))
    done < <($btctl devices Paired 2>/dev/null)

    choice="$(printf '%s\n' "''${entries[@]}" | $wofi --dmenu --prompt 'Bluetooth')" || exit 0
    key="''${choice%%|*}"

    case "$key" in
      A)
        if [[ "$powered" == "yes" ]]; then
          $btctl power off >/dev/null 2>&1 || true
        else
          $btctl power on >/dev/null 2>&1 || true
        fi
        ;;
      B)
        $btctl power on >/dev/null 2>&1 || true
        ${pkgs.coreutils}/bin/timeout 8 $btctl scan on >/dev/null 2>&1 || true

        declare -A scan_mac_by_key
        scan_entries=()
        j=1
        while IFS= read -r line; do
          [[ -z "$line" ]] && continue
          mac="$(printf '%s\n' "$line" | ${pkgs.gawk}/bin/awk '{print $2}')"
          name="$(printf '%s\n' "$line" | ${pkgs.gawk}/bin/awk '{$1="";$2="";sub(/^  */, ""); print}')"
          scan_key="S$j"
          scan_entries+=("$scan_key|$(bt_row " " "󰂯" "$name")")
          scan_mac_by_key["$scan_key"]="$mac"
          j=$((j + 1))
        done < <($btctl devices 2>/dev/null)

        scan_choice="$(printf '%s\n' "''${scan_entries[@]}" | $wofi --dmenu --prompt 'Pair device')" || exit 0
        scan_key="''${scan_choice%%|*}"
        mac="''${scan_mac_by_key[$scan_key]:-}"
        [[ -z "$mac" ]] && exit 0

        $btctl pair "$mac" >/dev/null 2>&1 || true
        $btctl trust "$mac" >/dev/null 2>&1 || true
        $btctl connect "$mac" >/dev/null 2>&1 || true
        ;;
      D*)
        mac="''${mac_by_key[$key]:-}"
        [[ -z "$mac" ]] && exit 0
        info="$($btctl info "$mac" 2>/dev/null || true)"
        connected="$(printf '%s\n' "$info" | ${pkgs.gawk}/bin/awk '/Connected:/ {print $2}')"
        trusted="$(printf '%s\n' "$info" | ${pkgs.gawk}/bin/awk '/Trusted:/ {print $2}')"

        actions=()
        if [[ "$connected" == "yes" ]]; then
          actions+=("1|󰂲  Disconnect")
        else
          actions+=("1|󰂱  Connect")
        fi
        if [[ "$trusted" == "yes" ]]; then
          actions+=("2|󰌾  Untrust")
        else
          actions+=("2|󰌾  Trust")
        fi
        actions+=("3|󰆴  Forget device")

        action_choice="$(printf '%s\n' "''${actions[@]}" | $wofi --dmenu --prompt 'Device action')" || exit 0
        action_key="''${action_choice%%|*}"

        case "$action_key" in
          1)
            if [[ "$connected" == "yes" ]]; then
              $btctl disconnect "$mac" >/dev/null 2>&1 || true
            else
              $btctl connect "$mac" >/dev/null 2>&1 || true
            fi
            ;;
          2)
            if [[ "$trusted" == "yes" ]]; then
              $btctl untrust "$mac" >/dev/null 2>&1 || true
            else
              $btctl trust "$mac" >/dev/null 2>&1 || true
            fi
            ;;
          3)
            $btctl remove "$mac" >/dev/null 2>&1 || true
            ;;
        esac
        ;;
    esac
  '';
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
          "custom/bluetooth"
          "custom/network"
          "battery"
        ];

        "hyprland/workspaces" = {
          format = "{icon}";
          format-icons = {
            "1" = "0x1";
            "2" = "0x2";
            "3" = "0x3";
            "4" = "0x4";
            "5" = "0x5";
            "6" = "0x6";
            "7" = "0x7";
            "8" = "0x8";
            "9" = "0x9";
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

        "custom/bluetooth" = {
          format = "{}";
          interval = 5;
          exec = "${bluetoothMenu}/bin/waybar-bluetooth-menu --status";
          on-click = "${bluetoothMenu}/bin/waybar-bluetooth-menu";
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

        "custom/network" = {
          format = "{}";
          interval = 5;
          exec = "${networkMenu}/bin/waybar-network-menu --status";
          on-click = "${networkMenu}/bin/waybar-network-menu";
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
        font-family: "Orbitron", "${fonts.monospace.name}", sans-serif;
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
      #custom-bluetooth,
      #custom-network,
      #battery,
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
      #custom-bluetooth:hover,
      #custom-network:hover,
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

      #custom-network {
        color: ${c.base05};
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

      #custom-bluetooth {
        color: ${c.base05};
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
