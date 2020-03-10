{fetchurl, lib}:

with lib;

let version = "6.0.14";
in
fetchurl rec {
  name = "Oracle_VM_VirtualBox_Extension_Pack-${version}.vbox-extpack";
  url = "https://download.virtualbox.org/virtualbox/${version}/${name}";
  sha256 =
    # Manually sha256sum the extensionPack file, must be hex!
    # Thus do not use `nix-prefetch-url` but instead plain old `sha256sum`.
    # Checksums can also be found at https://www.virtualbox.org/download/hashes/${version}/SHA256SUMS
    let value = "bcc88beba4e920290c914d6627199715b6f5917c57371884078c4bb3e3e12c95";
    in assert (builtins.stringLength value) == 64; value;

  meta = {
    description = "Oracle Extension pack for VirtualBox";
    license = licenses.virtualbox-puel;
    homepage = https://www.virtualbox.org/;
    maintainers = with maintainers; [ sander cdepillabout ];
    platforms = [ "x86_64-linux" ];
  };
}
