{ config, lib, ... }:

{
  launchd.agents.activate-agenix.config = {
    KeepAlive = lib.mkForce false;
    RunAtLoad = lib.mkForce false;
  };

  home.activation.activateAgenixInteractively = lib.hm.dag.entryAfter [ "setupLaunchAgents" ] ''
    run ${lib.escapeShellArgs config.launchd.agents.activate-agenix.config.ProgramArguments}
  '';
}
