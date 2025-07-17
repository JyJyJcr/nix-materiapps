{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        packages.itensor = pkgs.callPackage ./itensor.nix { };
        packages.hphi = pkgs.callPackage ./hphi.nix { };
        packages.quantum-espresso = pkgs.callPackage ./quantum-espresso.nix { };
        #packages.default = itensor;
        #devShells.default = pkgs.mkShell { packages = [ ]; };
      });
}
