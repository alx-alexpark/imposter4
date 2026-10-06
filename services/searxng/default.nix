{
  config,
  lib,
  pkgs,
  ...
}:
let
  domain = "search.sus.cx";
  # Turns on Caddy for the domain, behind basic auth. When false the UI is only
  # reachable over an SSH tunnel:
  #   ssh -L 8888:127.0.0.1:8888 root@<server>  then open http://localhost:8888
  public = true;

  docker = "${config.virtualisation.docker.package}/bin/docker";
  compose = "${docker} compose -p searxng -f ${./docker-compose.yml}";
  secretsFile = "/var/lib/secrets/searxng.env";

  # Merged over SearXNG's defaults, see
  # https://docs.searxng.org/admin/settings/index.html
  settings = {
    use_default_settings = true;
    general.instance_name = "Sussy Baka Search";
    server = {
      base_url = if public then "https://${domain}/" else "http://localhost:8888/";
      # only I can get past basic auth, so there's no one to rate limit
      limiter = false;
      # secret_key comes from SEARXNG_SECRET
    };
    # unused while the limiter is off; kept so turning it back on just works
    valkey.url = "valkey://valkey:6379/0";
    # Entries are merged into the default engine of the same name. Google and
    # Startpage are off by default; weight ranks Google first, then Startpage,
    # then the defaults (DuckDuckGo, Brave, ...), which stay on as a fallback.
    engines = [
      {
        name = "google";
        disabled = false;
        weight = 3;
      }
      {
        name = "startpage";
        inactive = false;
        disabled = false;
        weight = 2;
      }
    ];
  };

  configDir = pkgs.runCommand "searxng-config" { } ''
    mkdir $out
    cp ${(pkgs.formats.yaml { }).generate "settings.yml" settings} $out/settings.yml
  '';

  # The home page heading is a hard-coded SearXNG logo, so swap in a copy of
  # the upstream template that shows instance_name as text instead.
  # https://github.com/searxng/searxng/blob/master/searx/templates/simple/index.html
  indexTemplate = pkgs.writeText "index.html" ''
    {% extends "simple/base.html" %}
    {% from 'simple/icons.html' import icon_big %}
    {% block content %}
    <div class="index">
        <div class="title" style="background: none"><h1 style="visibility: visible">{{ instance_name }}</h1></div>
        {% include 'simple/simple_search.html' %}
    </div>
    {% endblock %}
  '';

  # The repo is public, so the secret key is generated on the server once.
  generateSecrets = pkgs.writeShellScript "searxng-secrets" ''
    if [ ! -f ${secretsFile} ]; then
      install -d -m 700 "$(dirname ${secretsFile})"
      umask 077
      printf 'SEARXNG_SECRET=%s\n' "$(${pkgs.openssl}/bin/openssl rand -hex 32)" > ${secretsFile}
    fi
  '';
in
{
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  systemd.services.searxng = {
    description = "SearXNG (docker compose)";
    wantedBy = [ "multi-user.target" ];
    after = [ "docker.service" "network-online.target" ];
    requires = [ "docker.service" ];
    wants = [ "network-online.target" ];
    environment = {
      SEARXNG_CONFIG = configDir;
      SEARXNG_INDEX_TEMPLATE = indexTemplate;
    };
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStartPre = generateSecrets;
      # --pull so restarts (e.g. the nightly auto-upgrade reboot) pick up new releases
      ExecStart = "${compose} up -d --pull always --remove-orphans";
      ExecStop = "${compose} down";
    };
  };

  services.caddy.virtualHosts = lib.mkIf public {
    ${domain} = {
      # access logs would record every query, since searches are GET /search?q=...
      logFormat = "output discard";
      # user sussy; make a new hash with `caddy hash-password`
      extraConfig = ''
        basic_auth {
          sussy $2a$14$caQAFHDF46tWUkQ0A7vMx.tm5hBPRCUefXhO1NKEcJ9X/tmgYHbom
        }
        reverse_proxy 127.0.0.1:8888
      '';
    };
  };
}
