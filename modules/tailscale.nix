{
  # Log in once after the first deploy, as root on the server:
  #   tailscale up
  # The node key persists in /var/lib/tailscale across reboots and upgrades.
  services.tailscale = {
    enable = true;
    # opens UDP 41641 so peers can connect directly instead of via DERP
    openFirewall = true;
  };
}
