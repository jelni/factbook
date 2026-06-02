{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      utils,
      ...
    }:
    utils.lib.eachDefaultSystem (
      system:
      let
        name = "factbook";
        pkgs = import nixpkgs { inherit system; };

        LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath (
          with pkgs;
          [
            cairo
            dbus
            gdk-pixbuf
            glib
            gtk3
            libsoup_3
            swi-prolog
            webkitgtk_4_1
          ]
        );
      in
      rec {
        packages.default = pkgs.rustPlatform.buildRustPackage {
          inherit name;
          src = pkgs.lib.cleanSource ./.;

          cargoLock = {
            lockFile = ./Cargo.lock;
            outputHashes."sparse-tags-0.1.1" = "sha256-NVAHl5d+CMfyNLMQIWZ3VbumAfj/pCxuLcjbiU8VfyY=";
          };

          pnpmDeps = pkgs.fetchPnpmDeps {
            pname = name;
            src = ./.;
            hash = "sha256-lwaE47iqb4WxWhUdvm9QPV38OVHVmZl2hwaG6CVrvxY=";
            fetcherVersion = 4;
          };

          buildInputs = with pkgs; [
            at-spi2-core.dev
            gtk3
            libsoup_3.dev
            pango.dev
            swi-prolog
            webkitgtk_4_1.dev
          ];

          nativeBuildInputs = with pkgs; [
            cargo-tauri
            nodejs
            pkg-config
            pnpm
            pnpmConfigHook
            rustPlatform.bindgenHook
            swi-prolog
            wrapGAppsHook3
          ];

          buildPhase = ''
            pnpm tauri build --no-bundle
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp target/release/${name} $out/bin/
          '';

          preFixup = ''
            gappsWrapperArgs+=(--prefix LD_LIBRARY_PATH : "${LD_LIBRARY_PATH}")
          '';
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            clippy
            rust-analyzer
            rustfmt
          ];

          inputsFrom = [ packages.default ];
          nativeBuildInputs = [ pkgs.rustPlatform.bindgenHook ];

          shellHook = ''
            export XDG_DATA_DIRS=${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS
          '';

          inherit LD_LIBRARY_PATH;
          LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
          RUST_SRC_PATH = pkgs.rustPlatform.rustLibSrc;
        };
      }
    );
}
