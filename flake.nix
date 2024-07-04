{
  description = "Templates and library functions for Nix flakes.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    systems = {
      url = "github:nix-systems/default";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, systems }:
    let
      lib = nixpkgs.lib.extend (import ./lib);
      eachSystem = lib.genAttrs (import systems);
    in {
      # an overlay is provided as `lib.overlay`
      lib = lib // { overlay = import ./lib; };
      templates = {
        rust-devshell = {
          description =
            "A flake that provides nothing but a default Rust development shell.";
          path = ./templates/rust-devshell;
          # welcomeText = "";
        };
        rust-package = {
          description =
            "A flake that provides a default Rust package and a development shell.";
          path = ./templates/rust-package;
          # welcomeText = "";
        };
      };
      formatter =
        eachSystem (system: nixpkgs.legacyPackages.${system}.nixfmt-classic);
    };
}
