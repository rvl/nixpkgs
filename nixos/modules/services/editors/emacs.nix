{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.emacs;

in {

  options.services.emacs = {
    enable = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        Enable Emacs daemon to have an always running Emacs. Use emacsclient to connect to the daemon..
      '';
    };

    package = mkOption {
      type = types.package;
      default = pkgs.emacs;
      defaultText = "pkgs.emacs";
      description = ''
        emacs derivation to use.
      '';
    };

  };

  config = mkIf cfg.enable {
    systemd.user.services.emacs = {
      description = "Emacs: the extensible, self-documenting text editor";

      serviceConfig = {
        Type      = "forking";
        ExecStart = "${pkgs.bash}/bin/bash -c 'source ${config.system.build.setEnvironment}; exec ${cfg.package}/bin/emacs --daemon'";
        ExecStop  = "${cfg.package}/bin/emacsclient --eval (kill-emacs)";
        Restart   = "always";
      };
    };

    environment.systemPackages = [ cfg.package ];
  };

}
