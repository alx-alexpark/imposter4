{
  modulesPath,
  lib,
  pkgs,
  ...
} @ args:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
  ];
  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  networking.hostName = "imposter4";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  time.timeZone = "America/New_York";

  system.autoUpgrade = {
    enable = true;
    flake = "github:alx-alexpark/imposter4#imposter4";
    # flake.lock is bumped daily by .github/workflows/update-flake.yml
    flags = [ "--refresh" ];
    # run inside the reboot window, otherwise reboots would always be skipped
    dates = "03:00";
    randomizedDelaySec = "30min";
    allowReboot = true;
    rebootWindow = {
      lower = "03:00";
      upper = "06:00";
    };
  };

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
  ];

  users.users.root.openssh.authorizedKeys.keys =
  [
    # change this to your ssh key
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIE4EqdlXF8o8Fdf0v/I8sowP7Rw3tZiY5i/CP131AX5dAAAAC3NzaDp0ZXJtaXVz"
    # "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID+oJpTmesL5Iiuiz7Bz1xlDZYsDD4dJ3nSoEjyjejfM a@susbook.local"
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIAKWfF9y67GxL3jIFcQfWvTOBOyIPtreimhYpxTHJ3CcAAAABHNzaDo= a@susbook.local"
  ] ++ (args.extraPublicKeys or []); # this is used for unit-testing this module and can be removed if not needed

  system.stateVersion = "24.05";
}