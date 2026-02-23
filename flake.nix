{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
    nix-jyjyjcr = {
      url = "github:jyjyjcr/nix-jyjyjcr";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { nixpkgs, flake-utils, nix-jyjyjcr, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ nix-jyjyjcr.overlays.default ];
        };
        pkgs-itensor = pkgs.callPackage ./itensor.nix { };
        pkgs-hphi = pkgs.callPackage ./hphi.nix { };
        pkgs-quantum-espresso = pkgs.callPackage ./quantum-espresso.nix { };
      in {
        packages.itensor = pkgs-itensor;
        packages.hphi = pkgs-hphi;
        packages.quantum-espresso = pkgs-quantum-espresso;
        devShells = pkgs.alt-shell.mkCommonShells { } {
          packages = [
            #pkgs-itensor
            #pkgs-hphi
            #pkgs-quantum-espresso
            #pkgs.pkg-config
            #pkgs.cmake
          ];
        };
      });
}
