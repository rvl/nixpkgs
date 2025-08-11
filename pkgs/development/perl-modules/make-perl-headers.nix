{ stdenv
, perl
, toPerlModule
, headerFiles ? [ ]  # e.g. [ "${pkgs.glibc.dev}/include/sys/syscall.h" ]
, headerDirs ? [ ]  # e.g. [ "${pkgs.glibc.dev}/include" ]
}:

toPerlModule (stdenv.mkDerivation {
  pname = "perl-headers";
  inherit (perl) version;

  nativeBuildInputs = [ perl ];

  inherit headerFiles headerDirs;

  dontUnpack = true;

  buildFlags = [ "-l" "-h" ];

  buildPhase = ''
    runHook preBuild

    mkdir -p build

    local flagsArray=(-d $PWD/build)
    concatTo flagsArray buildFlags buildFlagsArray

    echoCmd 'build flags' "''${flagsArray[@]}"

    local -a headerFilesArray
    concatTo headerFilesArray headerFiles

    for h in "''${headerFilesArray[@]}"; do
      mkdir -p build"$(dirname "$h")"
      h2ph "''${flagsArray[@]}" -a "$h"
    done

    local -a headerDirsArray
    concatTo headerDirsArray headerDirs

    for d in "''${headerDirsArray[@]}"; do
      h2ph "''${flagsArray[@]}" -r "$d"
    done

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    if [ -d 'build${builtins.storeDir}' ]; then
      cp -R 'build${builtins.storeDir}'/*/* build
      if [ -d build/include ]; then
        cp -R build/include/* build
        rm -rf build/include
      fi
    fi

    find build -path 'build${builtins.storeDir}' -prune -o -type f -name '*.ph' -print0 | while IFS="" read -r -d "" ph; do
      sed -i -e 's,${builtins.storeDir}/[^/]\+,'"$out"',g' "$ph"
      install -v -D -m0644 "$ph" "$out/include/''${ph#build/}"
    done

    runHook postInstall
  '';
})
