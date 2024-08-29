{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    systems = {
      url = "github:nix-systems/default";
      flake = false;
    };
  };
  outputs = { self, nixpkgs, rust-overlay, systems }:
    let
      inherit (nixpkgs) lib;
      eachSystem = lib.genAttrs (import systems);
      pkgsFor = eachSystem (system:
        import nixpkgs {
          localSystem = system;
          overlays = [ rust-overlay.overlays.default ];
        });

      packageName = (lib.importTOML ./Cargo.toml).package.name;
    in {
      overlays = {
        default = lib.composeManyExtensions [ self.overlays.${packageName} ];

        ${packageName} = final: _:
          let
            rust-bin = rust-overlay.lib.mkRustBin { } final;
            rust-stable = rust-bin.stable.latest.minimal;
            rustPlatform = final.makeRustPlatform {
              cargo = rust-stable;
              rustc = rust-stable;
            };
          in {
            ${packageName} = final.callPackage ./nix/package.nix {
              sourceRoot = self;
              inherit rustPlatform;
            };
          };
      };

      packages = lib.mapAttrs (system: pkgs: {
        default = self.packages.${system}.${packageName};
        ${packageName} = pkgs.${packageName};
      }) pkgsFor;

      devShells = lib.mapAttrs (system: pkgs:
        let
          rust-stable = pkgs.rust-bin.stable.latest.minimal.override {
            extensions = [ "rust-src" "rust-docs" "clippy" ];
          };
        in {
          default = pkgs.mkShell {
            strictDeps = true;
            packages = with pkgs; [
              # Derivations in `rust-stable` take precedence over nightly.
              (lib.hiPrio rust-stable)

              # Use rustfmt, and other tools that require nightly features.
              (rust-bin.selectLatestNightlyWith (toolchain:
                toolchain.minimal.override {
                  extensions = [ "rustfmt" "rust-analyzer" ];
                }))
            ];
          };
        }) pkgsFor;

      formatter = eachSystem (system: pkgsFor.${system}.nixfmt-classic);
    };
}
