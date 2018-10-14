{ stdenv, fetchFromGitHub, fetchurl, cmake, pkgconfig, ninja, zlib, expat ? null, rpm ? null, db ? null, staticBuild ? false, pcre }:

stdenv.mkDerivation rec {
  rev  = "0.6.29";
  name = "libsolv-${rev}";

  src = fetchFromGitHub {
    inherit rev;
    owner  = "openSUSE";
    repo   = "libsolv";
    sha256 = "0p44qn2g5c6xv89h79x5y6ciwwqxfmxkmkk24nh22lx67j91w6y5";
  };

  cmakeFlags = [ "-DENABLE_COMPLEX_DEPS=true" "-DENABLE_PUBKEY=true" ]
    ++ stdenv.lib.optional (rpm != null && expat != null) "-DENABLE_RPMMD=true"
    ++ stdenv.lib.optionals (rpm != null) [
      "-DENABLE_RPMDB=true"
      "-DENABLE_RPMDB_BYRPMHEADER=true"
    ]
    ++ stdenv.lib.optionals staticBuild [
      "-DENABLE_STATIC=ON"
      "-DDISABLE_SHARED=ON"
      "-DCMAKE_SHARED_LIBRARY_LINK_C_FLAGS=\"\""
      "-DCMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS=\"\""
    ];

  prePatch = ''
    mv CMakeLists.txt tmp
    cat > CMakeLists.txt <<EOF
    SET(CMAKE_SYSTEM_NAME Windows)
    EOF
    cat tmp >> CMakeLists.txt
    rm tmp
    cat >> CMakeLists.txt << EOF
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(PCRE REQUIRED libpcre)
    EOF
  '';

  patches = [ (fetchurl {
    url = "https://copr-dist-git.fedorainfracloud.org/cgit/jturney/mingw-libsolv/mingw-libsolv.git/plain/0001-Fix-building-on-MinGW-w64.patch";
    sha256 = "1dwjyfjb5zkxk8rk9icc3rdki1j4cblfb7hv6r0mqi76yx3m5ym7";
  }) ];

  nativeBuildInputs = [ cmake ninja pkgconfig ];
  buildInputs = stdenv.lib.filter (drv: drv != null) [ zlib expat rpm db pcre ];

  meta = with stdenv.lib; {
    description = "A free package dependency solver";
    license     = licenses.bsd3;
    platforms   = platforms.all;
    maintainers = with maintainers; [ copumpkin ];
  };
}

