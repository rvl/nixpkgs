#!/usr/bin/env nix-shell
#!nix-shell --pure -i bash -p nix nodePackages.bower2nix

rm -f bower-packages.nix
bower2nix bower.json bower-packages.nix
