{ config, pkgs, lib, ... }:

{
  imports = [ ];

  # Placeholder so flake evaluation succeeds before first install.
  # Replace this file with nixos-generate-config output on scar.

  boot.initrd.availableKernelModules = [ ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/REPLACE-WITH-SCAR-ROOT-UUID";
    fsType = "ext4";
  };

  swapDevices = [ ];
}
