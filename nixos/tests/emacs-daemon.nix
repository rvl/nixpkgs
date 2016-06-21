import ./make-test.nix ({ pkgs, ...} : {
  name = "emacs-daemon";
  meta = with pkgs.stdenv.lib.maintainers; {
    maintainers = [ DamienCassou ];
  };

  enableOCR = true;

  machine =
    { config, pkgs, ... }:

    { imports = [ ./common/x11.nix ];
      services.emacs = {
        enable = true;
        defaultEditor = true;
      };

      # Important to get the systemd service running for root
      environment.variables.XDG_RUNTIME_DIR = "/run/user/0";
    };

  testScript =
    ''
      $machine->waitForUnit("multi-user.target");
      $machine->sleep(1); # sometimes fails without that
      $machine->succeed("systemctl --user daemon-reload");

      # checks that the EDITOR environment variable is set
      $machine->succeed("test \$(basename \"\$EDITOR\") = editor-emacs.sh");

      # starts Emacs daemon
      $machine->succeed("systemctl --user start emacs");

      # connects to the daemon
      $machine->succeed("emacsclient --create-frame \$EDITOR &");

      # checks that Emacs shows the edited filename
      $machine->waitForText("editor-emacs.sh");

      $machine->screenshot("emacsclient");
    '';
})
