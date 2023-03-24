{
  description = "DRControl";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }: let
    systems = with flake-utils.lib.system; [
      x86_64-linux
      aarch64-linux
      riscv64-linux
    ];
  in
    flake-utils.lib.eachSystem systems (system: {
      packages.drcontrol = nixpkgs.legacyPackages.${system}.callPackage ./drcontrol.nix {};
      packages.default = self.packages.${system}.drcontrol;
      formatter = nixpkgs.legacyPackages.${system}.alejandra;
    });
}
