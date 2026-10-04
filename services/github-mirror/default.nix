{
  lib,
  pkgs,
  ...
}:
let
  # GitHub repos to mirror into Forgejo, as "owner/name". Removing one here
  # doesn't delete its mirror; do that in the Forgejo UI.
  repos = [
    "alx-alexpark/VVVF"
    "alx-alexpark/AmogusRP2040"
    "alx-alexpark/hacknight-run"
    "alx-alexpark/led-matrix-badge"
    "alx-alexpark/nixie-clock"
    "alx-alexpark/parkalex.dev-ng"
    "alx-alexpark/radio-keychain"
  ];

  mirror = pkgs.writeShellApplication {
    name = "github-mirror";
    runtimeInputs = [ pkgs.curl pkgs.jq ];
    text = builtins.readFile ./mirror.sh;
  };
in
{
  # Create tokens before this runs, as root on the server:
  #   install -m 600 /dev/null /var/lib/secrets/github-mirror.env
  #   then add FORGEJO_TOKEN=... and (for private repos) GITHUB_TOKEN=...
  systemd.services.github-mirror = {
    description = "Mirror GitHub repos into Forgejo";
    after = [ "forgejo.service" "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      EnvironmentFile = "/var/lib/secrets/github-mirror.env";
      ExecStart = "${lib.getExe mirror} ${lib.escapeShellArgs repos}";
      DynamicUser = true;
    };
  };

  # Hourly so repos added to the list show up soon after a deploy
  systemd.timers.github-mirror = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
    };
  };
}
