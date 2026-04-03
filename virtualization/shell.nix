{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  packages = with pkgs; [
    qemu
    cdrkit  # provides genisoimage (for cloud-init seed ISO)
  ];
}
