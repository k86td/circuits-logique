{
  description = "Digital - a digital logic designer and circuit simulator";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f:
        nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: rec {
        default = digital;

        digital = pkgs.callPackage ./nix/digital.nix { };

        # Same app, plus the external HDL tools Digital can shell out to
        # (VHDL/Verilog export + simulation, waveform viewing).
        digital-with-hdl = digital.override { withHdlTools = true; };
      });

      apps = forAllSystems (pkgs: rec {
        default = digital;
        digital =
          let pkg = self.packages.${pkgs.stdenv.hostPlatform.system}.digital; in
          {
            type = "app";
            program = "${pkg}/bin/digital";
            meta = pkg.meta;
          };
      });

      devShells = forAllSystems (pkgs:
        let
          # Runs the Digital.jar sitting in the current directory, instead of
          # the immutable /nix/store copy. Handy while swapping jar versions.
          digital-local = pkgs.writeShellScriptBin "digital-local" ''
            jar="''${DIGITAL_JAR:-$PWD/Digital.jar}"
            if [ ! -f "$jar" ]; then
              echo "digital-local: no Digital.jar at $jar" >&2
              echo "cd to the Digital directory, or set DIGITAL_JAR." >&2
              exit 1
            fi
            exec ${pkgs.lib.getExe' pkgs.jdk21 "java"} \
              ${pkgs.lib.escapeShellArgs (import ./nix/java-flags.nix)} \
              -jar "$jar" "$@"
          '';
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.jdk21
              digital-local
              self.packages.${pkgs.stdenv.hostPlatform.system}.digital
            ];

            # Swing/AWT under a non-reparenting Wayland compositor (niri, sway,
            # river) via XWayland: AWT only recognises a hardcoded list of
            # reparenting X11 WMs, and mis-maps its content window under any
            # other one, painting a blank grey frame. Force the
            # non-reparenting code path.
            _JAVA_AWT_WM_NONREPARENTING = "1";

            shellHook = ''
              echo "Digital dev shell"
              echo "  digital        run the packaged build (read-only /nix/store copy)"
              echo "  digital-cli    headless: test / svg / verilog export"
              echo "  digital-local  run ./Digital.jar from this directory"
            '';
          };
        });

      overlays.default = final: prev: {
        digital = final.callPackage ./nix/digital.nix { };
      };

      formatter = forAllSystems (pkgs: pkgs.nixpkgs-fmt);
    };
}
