{
  config,
  lib,
  ...
}:
let
  # Any service that adds a virtual host turns Caddy on
  enabled = config.services.caddy.virtualHosts != { };
in
{
  services.caddy.enable = enabled;

  networking.firewall.allowedTCPPorts = lib.optionals enabled [ 80 443 ];
  # HTTP/3
  networking.firewall.allowedUDPPorts = lib.optionals enabled [ 443 ];
}
