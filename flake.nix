{
  description = "notenav – TUI faceted browser for markdown notebooks";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f {
        pkgs = nixpkgs.legacyPackages.${system};
      });
      runtimeDepsFor = pkgs: with pkgs; [
        bash
        zk
        fzf
        bat
        gawk
        gnused
        coreutils
        ncurses  # provides tput (used for terminal width)
        yq-go
        jq
        curl
      ];
    in
    {
      packages = forAllSystems ({ pkgs }:
        let runtimeDeps = runtimeDepsFor pkgs;
        in {
          default = pkgs.stdenv.mkDerivation {
            pname = "notenav";
            version = "0.1.0-dev";
            src = ./.;

            nativeBuildInputs = [ pkgs.makeWrapper ];

            dontBuild = true;

            installPhase = ''
              runHook preInstall
              mkdir -p $out/bin $out/lib $out/config/workflows
              install -m755 bin/nn $out/bin/nn
              install -m644 lib/notenav.sh $out/lib/notenav.sh
              install -m644 config/base.toml $out/config/base.toml
              install -m644 config/workflows/*.toml $out/config/workflows/
              wrapProgram $out/bin/nn \
                --prefix PATH : ${pkgs.lib.makeBinPath runtimeDeps}
              runHook postInstall
            '';

            meta = with pkgs.lib; {
              description = "TUI faceted browser for markdown notebooks";
              homepage = "https://github.com/jqueiroz/notenav";
              license = licenses.mit;
              platforms = platforms.unix;
              mainProgram = "nn";
            };
          };
        }
      );

      devShells = forAllSystems ({ pkgs }:
        let runtimeDeps = runtimeDepsFor pkgs;
        in {
          default = pkgs.mkShell {
            packages = runtimeDeps;

            shellHook = ''
              export PATH="$PWD/bin:$PATH"
            '';
          };
        });
    };
}
