# NixOS configuration for the notenav test VM.
# Built into a qcow2 image by launch.sh via nixos-generators.
{ pkgs, ... }: {
  # Serial console for QEMU -nographic
  boot.kernelParams = [ "console=ttyS0,115200n8" ];
  boot.loader.grub.extraConfig = ''
    serial --unit=0 --speed=115200
    terminal_input serial console
    terminal_output serial console
  '';

  networking.hostName = "nixos-test";

  # SSH
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
  };

  # User
  users.users.nixos = {
    isNormalUser = true;
    initialPassword = "nixos";
    extraGroups = [ "wheel" ];
  };
  security.sudo.wheelNeedsPassword = false;

  # notenav dependencies
  environment.systemPackages = with pkgs; [
    bash
    gawk
    fzf
    jq
    yq-go
    git
    ripgrep
    bat
    curl
  ];

  # Add synced notenav to PATH
  environment.shellInit = ''
    if [ -d "$HOME/notenav/bin" ]; then
      export PATH="$HOME/notenav/bin:$PATH"
    fi
  '';

  system.stateVersion = "24.11";
}
