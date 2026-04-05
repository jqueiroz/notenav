{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  packages = with pkgs; [
    qemu
    cdrkit  # provides genisoimage (for cloud-init seed ISO)
  ];

  # UEFI firmware for Gentoo VM (the image is EFI-only)
  OVMF_FD = "${pkgs.OVMF.fd}/FV/OVMF.fd";
}
