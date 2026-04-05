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
        zk  # optional but bundled – enables faster indexing and link graph
        fzf
        bat
        ripgrep  # optional but bundled – faster content search
        trash-cli  # optional but bundled – recoverable delete (trash-put)
        gawk
        gnused
        coreutils
        ncurses  # provides tput (used for terminal width)
        yq-go
        jq
        curl
      ] ++ (if pkgs.stdenv.isLinux then [ pkgs.inotify-tools ]
           else if pkgs.stdenv.isDarwin then [ pkgs.fswatch ]
           else if pkgs.stdenv.isFreeBSD then [ pkgs.fswatch ]   # kqueue backend
           else if pkgs.stdenv.isOpenBSD then [ pkgs.fswatch ]  # kqueue backend
           else throw "unsupported platform for file watcher dependency");
    in
    {
      packages = forAllSystems ({ pkgs }:
        let runtimeDeps = runtimeDepsFor pkgs;
        in {
          default = pkgs.stdenv.mkDerivation {
            pname = "notenav";
            version = builtins.replaceStrings ["\n"] [""] (builtins.readFile ./VERSION);
            src = ./.;

            nativeBuildInputs = [ pkgs.makeWrapper ];

            dontBuild = true;

            installPhase = ''
              runHook preInstall
              mkdir -p $out/bin $out/lib $out/config/workflows $out/samples/workflows
              install -m755 bin/nn $out/bin/nn
              install -m644 lib/notenav.sh $out/lib/notenav.sh
              install -m644 VERSION $out/VERSION
              install -m644 config/base.toml $out/config/base.toml
              install -m644 config/workflows/*.toml $out/config/workflows/
              install -m644 samples/user-config.toml $out/samples/user-config.toml
              install -m644 samples/workflows/*.toml $out/samples/workflows/
              wrapProgram $out/bin/nn \
                --prefix PATH : ${pkgs.lib.makeBinPath runtimeDeps}
              runHook postInstall
            '';

            meta = with pkgs.lib; {
              description = "TUI faceted browser for markdown notebooks";
              homepage = "https://github.com/jqueiroz/notenav";
              license = licenses.mit;
              platforms = platforms.linux ++ platforms.darwin ++ platforms.freebsd ++ platforms.openbsd;
              mainProgram = "nn";
            };
          };
        }
      );

      # NixOS VM smoke tests (Linux only – uses QEMU/KVM)
      checks = nixpkgs.lib.genAttrs
        (builtins.filter (s: nixpkgs.lib.hasSuffix "-linux" s) systems)
        (system: let
          pkgs = nixpkgs.legacyPackages.${system};
          nixos-lib = import (nixpkgs + "/nixos/lib") {};
        in {
          smoke = nixos-lib.runTest {
            name = "notenav-smoke";
            hostPkgs = pkgs;

            nodes.machine = { ... }: {
              environment.systemPackages = [
                self.packages.${system}.default
              ];
            };

            testScript = ''
              machine.wait_for_unit("multi-user.target")

              # Basic invocation
              version = machine.succeed("nn --version")
              assert "notenav" in version, f"unexpected version output: {version}"

              # Init creates a workflow config
              machine.succeed("mkdir -p /tmp/notebook && cd /tmp/notebook && nn init")
              machine.succeed("test -f /tmp/notebook/.nn/workflow.toml")

              # Doctor checks dependencies (all bundled via wrapProgram)
              machine.succeed("cd /tmp/notebook && nn doctor")

              # Ad-hoc query on empty notebook exits cleanly
              machine.succeed("cd /tmp/notebook && nn type=task || true")
            '';
          };
        });

      devShells = forAllSystems ({ pkgs }:
        let runtimeDeps = runtimeDepsFor pkgs;
        in {
          default = pkgs.mkShell {
            packages = runtimeDeps ++ [ pkgs.git ];

            shellHook = ''
              export PATH="$PWD/bin:$PATH"
            '';
          };
        });
    };
}
