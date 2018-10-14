{ stdenv, fetchgit, autoconf, automake, libtool, flex, bison, pkgconfig
, zlibStatic, bzip2, xz, zstd, libgcrypt, libgpgerror, libsolv
}:

with stdenv.lib;

let
    mkStatic = flip overrideDerivation (o: {
      dontDisableStatic = true;
      configureFlags = toList (o.configureFlags or []) ++ [ "--enable-static" "--disable-shared" ];
      buildInputs = map mkStatic (o.buildInputs or []);
      propagatedBuildInputs = map mkStatic (o.propagatedBuildInputs or []);
    });
    gcryptStatic = mkStatic libgcrypt;
in 

stdenv.mkDerivation rec {
  name = "cygwin-setup-${version}";
  version = "2.11.1";

  src = /nix/store/2qapm7xssidk1rm03lf2chjsy69m2mfs-setup;
  # src = fetchgit {
  #   url = "git://sourceware.org/git/newlib-cygwin.git";
  #   rev = "86c31ae47b1a17e8d79968af2874b2a89b4326c5";
  #   sha256 = "0zl0808czssa1pnyk8kwg8ddz73flhz1v6j1sr2n3nm2f981h3q8";
  # };
  # src = fetchgit {
  #   url = git://sourceware.org/git/cygwin-apps/setup.git;
  #   rev = "7a524bf7194058086410dc442a7cc1405c6f92a0";
  #   sha256 = "1lm73sn2784ip0k1y0dch6s0vmfb7m5l0fp8pxmawl31km68fg9w";
  # };

  nativeBuildInputs = [ autoconf automake libtool flex bison pkgconfig libgcrypt.dev ];

  buildInputs = [
    gcryptStatic
    (mkStatic libgpgerror)
    (mkStatic zstd)  # fixme multiple outputs would help
    (mkStatic (libsolv.override { zlib = zlibStatic; expat = null; rpm = null; db = null; }))
    zlibStatic.dev zlibStatic.static
    (bzip2.override { linkStatic = true; })
    (xz.override { enableStatic = true; })
  ];

  configureFlags = [ "--enable-static" "--disable-shared" ];
  NIX_CFLAGS_COMPILE = [ "-Wno-error" ];

  dontDisableStatic = true;

  preConfigure = ''
    autoreconf -vfi
  '';

  installPhase = ''
    install -vD setup.exe "$out/bin/setup.exe"
  '';

  # patches = [ ./fix-cygwin-setup.patch ];

  meta = {
    homepage = https://sourceware.org/cygwin-apps/setup.html;
    description = "A tool for installing Cygwin";
    license = licenses.gpl2Plus;
  };
}
