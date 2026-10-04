{
  # Log in once after the first deploy, as root on the server:
  #   tailscale up
  # The node key persists in /var/lib/tailscale across reboots and upgrades.
  # Then approve the exit node in the Tailscale admin console (Machines → Edit route settings).
  services.tailscale = {
    enable = true;
    # opens UDP 41641 so peers can connect directly instead of via DERP
    openFirewall = true;
    # IP forwarding and loose reverse-path filtering, needed to be an exit node
    useRoutingFeatures = "server";
    extraSetFlags = [
      # keep the host's own resolver instead of MagicDNS
      "--accept-dns=false"
      "--advertise-exit-node"
    ];
  };
}
