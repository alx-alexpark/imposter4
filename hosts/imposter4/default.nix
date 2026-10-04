{
  modulesPath,
  ...
} @ args:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
    ./hardware-configuration.nix
    ../../modules/base.nix
    ../../modules/auto-upgrade.nix
    ../../services/forgejo
    ../../services/github-mirror
  ];

  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  networking.hostName = "imposter4";

  time.timeZone = "America/New_York";

  users.users.root.openssh.authorizedKeys.keys =
  [
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIE4EqdlXF8o8Fdf0v/I8sowP7Rw3tZiY5i/CP131AX5dAAAAC3NzaDp0ZXJtaXVz"
    # "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID+oJpTmesL5Iiuiz7Bz1xlDZYsDD4dJ3nSoEjyjejfM a@susbook.local"
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIAKWfF9y67GxL3jIFcQfWvTOBOyIPtreimhYpxTHJ3CcAAAABHNzaDo= a@susbook.local"
  ] ++ (args.extraPublicKeys or []); # this is used for unit-testing this module and can be removed if not needed

  system.stateVersion = "24.05";
}
