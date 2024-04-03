{
  description = "Templates and library functions for Nix flakes.";

  inputs = {
    nixpkgs-lib.url = "github:nix-community/nixpkgs.lib";
    systems.url = "github:nix-systems/default";
    nixfmt.url = "github:serokell/nixfmt/v0.6.0";
  };

  outputs = { self, nixpkgs-lib, systems, nixfmt }:
    let
      inherit (nixpkgs-lib) lib;
      eachSystem = lib.genAttrs (import systems);
    in { formatter = eachSystem (system: nixfmt.packages.${system}.nixfmt); };
}
