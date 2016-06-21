{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.emacs;

  editorScript = pkgs.writeScriptBin "editor-emacs.sh" ''
    #!${pkgs.stdenv.shell}
    if [ -z "$1" ]; then
      exec ${cfg.package}/bin/emacsclient --create-frame --alternate-editor ${cfg.package}/bin/emacs
    else
      exec ${cfg.package}/bin/emacsclient --alternate-editor ${cfg.package}/bin/emacs "$@"
    fi
  '';

in {

  options.services.emacs = {
    enable = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        Whether to install a user service for the Emacs daemon. Once
        the service is started, use emacsclient to connect to the
        daemon.

        The service must be manually started and/or enabled for each
        user with "systemctl --user start emacs" and
        "systemctl --user enable emacs".
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

    defaultEditor = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        When enabled, configures emacsclient to be the default editor
        using the EDITOR environment variable.
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

    environment.systemPackages = [ cfg.package editorScript ];

    environment.variables = if cfg.defaultEditor then {
      EDITOR = mkOverride 900 "${editorScript}/bin/editor-emacs.sh";
    } else {};
  };
}
