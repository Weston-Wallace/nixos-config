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
    ../../modules/common/base.nix
    ../../modules/common/user-westonw.nix
    ../../modules/roles/desktop.nix
  ];

  # Use the latest kernel - recommended for AI 300 series
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nullrunner";
  networking.networkmanager.enable = true;

  # Load amdgpu early for both GPUs
  hardware.amdgpu.initrd.enable = true;

  # User
  users.users.westonw.extraGroups = [
    "video"
    "lp"
    "plugdev"
  ];

  # Don't change this ever
  system.stateVersion = "25.11";
}
