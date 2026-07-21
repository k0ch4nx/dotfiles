{ lib, ... }:

{
  launchd.agents.activate-agenix.config.KeepAlive = lib.mkForce false;
}
