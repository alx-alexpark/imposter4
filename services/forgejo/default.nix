{
  config,
  lib,
  pkgs,
  ...
}:
let
  domain = "git.parkalex.dev";
  # Turns on Caddy for the domain and exposes git SSH on 222. When false the web
  # UI is only reachable over an SSH tunnel:
  #   ssh -L 3000:127.0.0.1:3000 root@<server>  then open http://localhost:3000
  # The install wizard is locked (INSTALL_LOCK in docker-compose.yml) either way.
  public = true;

  docker = "${config.virtualisation.docker.package}/bin/docker";
  compose = "${docker} compose -p forgejo -f ${./docker-compose.yml}";
  secretsFile = "/var/lib/secrets/forgejo.env";

  # The repo is public, so the DB password is generated on the server once.
  generateSecrets = pkgs.writeShellScript "forgejo-secrets" ''
    if [ ! -f ${secretsFile} ]; then
      install -d -m 700 "$(dirname ${secretsFile})"
      pw=$(${pkgs.openssl}/bin/openssl rand -hex 32)
      umask 077
      printf 'POSTGRES_PASSWORD=%s\nFORGEJO__database__PASSWD=%s\n' "$pw" "$pw" > ${secretsFile}
    fi
  '';
in
{
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  systemd.services.forgejo = {
    description = "Forgejo (docker compose)";
    wantedBy = [ "multi-user.target" ];
    after = [ "docker.service" "network-online.target" ];
    requires = [ "docker.service" ];
    wants = [ "network-online.target" ];
    environment = {
      FORGEJO_DOMAIN = domain;
      FORGEJO_SSH_BIND = if public then "0.0.0.0" else "127.0.0.1";
    };
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStartPre = generateSecrets;
      # --pull so restarts (e.g. the nightly auto-upgrade reboot) pick up patch releases
      ExecStart = "${compose} up -d --pull always --remove-orphans";
      ExecStop = "${compose} down";
    };
  };

  services.caddy.virtualHosts = lib.mkIf public {
    ${domain}.extraConfig = ''
      reverse_proxy 127.0.0.1:3000
    '';
  };

  # Docker publishes 222 itself, but list it so the open ports are visible here.
  networking.firewall.allowedTCPPorts = lib.optionals public [ 222 ];
}
