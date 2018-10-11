{ stdenv, fetchurl, runCommand, python, xorriso, closureInfo, pathsFromGraph
, arch ? "x86_64"
}:

{ packages ? []
, mirror ? "http://ftp.gwdg.de/pub/linux/sources.redhat.com/cygwin"
, extraContents ? []
}:

let
  cygPkgList = if arch == "x86_64" then fetchurl {
    url = "${mirror}/x86_64/setup.ini";
    sha256 = "15fxgikqpk2gxd5pj6hywvv6d702rhj8n9sw6kmds4vwqrim0y2k";
  } else fetchurl {
    url = "${mirror}/x86/setup.ini";
    sha256 = "1fayx34868vd5h2nah7chiw65sl3i9qzrwvs7lrlv2h8k412vb69";
  };

  cygwinCross = (import ../../../../.. {
    localSystem = stdenv.hostPlatform;
    crossSystem = {
      libc = "msvcrt";
      platform = {};
      inherit arch;
      config = "${arch}-pc-mingw32";
    };
  }).windows.cygwinSetup;

  makeCygwinClosure = { packages, packageList }: let
    expr = import (runCommand "cygwin.nix" { buildInputs = [ python ]; } ''
      python ${./mkclosure.py} "${packages}" ${toString packageList} > "$out"
    '');
    gen = { url, hash }: {
      source = fetchurl {
        url = "${mirror}/${url}";
        sha512 = hash;
      };
      target = url;
    };
  in map gen expr;

in import ../../../../../nixos/lib/make-iso9660-image.nix {
  inherit stdenv closureInfo xorriso;
  syslinux = null;
  contents = [
    { source = "${cygwinCross}/bin/setup.exe";
      target = "setup.exe";
    }
    { source = cygPkgList;
      target = "setup.ini";
    }
  ] ++ makeCygwinClosure {
    packages = cygPkgList;
    packageList = packages;
  } ++ extraContents;
}
