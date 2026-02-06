{ config, pkgs, lib, ... }:

{
  services.mako = {
    enable = true;

    settings = {
      # Layout
      border-radius = 10;
      border-size = 2;
      padding = "12";
      margin = "10";
      width = 350;
      max-visible = 5;
      default-timeout = 5000;

      # Position
      anchor = "top-right";

      # Urgency overrides (timeouts only - colors handled by Stylix)
      "[urgency=low]" = {
        default-timeout = 3000;
      };

      "[urgency=high]" = {
        default-timeout = 10000;
      };
    };
  };
}
