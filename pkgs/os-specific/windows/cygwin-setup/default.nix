{ stdenv, fetchcvs, autoconf, automake, libtool, flex, bison, pkgconfig
, zlibStatic, bzip2, xz, libgcrypt
}:

with stdenv.lib;

stdenv.mkDerivation rec {
  name = "cygwin-setup-${version}";
  version = "20131101";

  src = fetchcvs {
    cvsRoot = ":pserver:anoncvs@cygwin.com:/cvs/cygwin-apps";
    module = "setup";
    date = version;
    sha256 = "024wxaaxkf7p1i78bh5xrsqmfz7ss2amigbfl2r5w9h87zqn9aq3";
  };

  nativeBuildInputs = [ autoconf automake libtool flex bison pkgconfig ];

  buildInputs = let
    mkStatic = flip overrideDerivation (o: {
      dontDisableStatic = true;
      configureFlags = toList (o.configureFlags or []) ++ [ "--enable-static" ];
      buildInputs = map mkStatic (o.buildInputs or []);
      propagatedBuildInputs = map mkStatic (o.propagatedBuildInputs or []);
    });
  in [ (mkStatic libgcrypt) bzip2 zlibStatic (xz.override { enableStatic = true; }) ];

  configureFlags = [ "--disable-shared" ];

  dontDisableStatic = true;

  preConfigure = ''
    autoreconf -vfi
  '';

  installPhase = ''
    install -vD setup.exe "$out/bin/setup.exe"
  '';

  meta = {
    homepage = https://sourceware.org/cygwin-apps/setup.html;
    description = "A tool for installing Cygwin";
    license = licenses.gpl2Plus;
  };
}
