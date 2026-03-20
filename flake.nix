{
  description = "notenav — TUI faceted browser for zk notebooks";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f {
        pkgs = nixpkgs.legacyPackages.${system};
      });
    in
    {
      devShells = forAllSystems ({ pkgs }: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            zsh
            zk
            fzf
            bat
            gawk
            gnused
            coreutils
          ];

          shellHook = ''
            export PATH="$PWD/bin:$PATH"
          '';
        };
      });
    };
}
