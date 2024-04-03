{
  description = "Templates and library functions for Nix flakes.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    nixfmt.url = "github:serokell/nixfmt/v0.6.0";
  };

  outputs = { self, nixpkgs, systems, nixfmt }:
    let
      lib = nixpkgs.lib.extend (import ./lib);
      eachSystem = lib.genAttrs (import systems);
    in {
      # an overlay is provided as `lib.overlay`
      lib = lib // { overlay = import ./lib; };
      formatter = eachSystem (system: nixfmt.packages.${system}.nixfmt);
    };
}
