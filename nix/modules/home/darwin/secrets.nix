{ config, lib, ... }:

{
  age.secrets.rift-codesign = {
    file = ../../../../secrets/codesign/rift.pem.age;
    path = "${config.home.homeDirectory}/.local/state/rift-signed/codesign.pem";
    mode = "600";
  };

  launchd.agents.activate-agenix.config = {
    KeepAlive = lib.mkForce false;
    RunAtLoad = lib.mkForce false;
  };

  home.activation.activateAgenixInteractively = lib.hm.dag.entryAfter [ "setupLaunchAgents" ] ''
    run ${lib.escapeShellArgs config.launchd.agents.activate-agenix.config.ProgramArguments}
  '';
}
