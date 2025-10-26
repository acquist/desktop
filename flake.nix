{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    naersk.url = "github:nix-community/naersk";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs =
    {
      self,
      flake-utils,
      naersk,
      nixpkgs,
      rust-overlay
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = (import nixpkgs) {
          inherit system;
          overlays = [
            (import rust-overlay)
          ];
        };

        naersk' = pkgs.callPackage naersk { };

        buildInputs = with pkgs; [
          at-spi2-atk
          atkmm
          cairo
          gdk-pixbuf
          glib
          gtk3
          harfbuzz
          librsvg
          libsoup_3
          pango
          webkitgtk_4_1
          openssl
        ];

        nativeBuildInputs = with pkgs; [
          (pkgs.rust-bin.stable.latest.default.override {
            extensions = [
              "rust-src"
              "cargo"
              "rustc"
            ];
          })

          pkg-config
          gobject-introspection
          cargo 
          cargo-tauri
          nodejs
        ];
      in
      rec {
        defaultPackage = packages.acquist;
        packages = {
          acquist = naersk'.buildPackage {
            src = ./.;
            nativeBuildInputs = nativeBuildInputs;
            buildInputs = buildInputs;
          };
          container = pkgs.dockerTools.buildImage {
            name = "acquist";
            config = {
              entrypoint = [ "${packages.acquist}/bin/acquist" ];
            };
          };
        };

        devShell = pkgs.mkShell {
          RUST_SRC_PATH = "${
            pkgs.rust-bin.stable.latest.default.override {
              extensions = [ "rust-src" ];
            }
          }/lib/rustlib/src/rust/library";

          nativeBuildInputs =
            with pkgs;
            [
              nixfmt
              cmake
              rustc
              rustfmt
              cargo
              clippy
              rust-analyzer
            ]
            ++ buildInputs
            ++ nativeBuildInputs;

          shellHook = ''
            npm i
          '';
        };
      }
    );
}