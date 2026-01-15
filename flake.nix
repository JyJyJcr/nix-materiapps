{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        pkgs-itensor = pkgs.callPackage ./itensor.nix { };
        pkgs-hphi = pkgs.callPackage ./hphi.nix { };
        pkgs-quantum-espresso = pkgs.callPackage ./quantum-espresso.nix { };

        shell-pkgs = [
          pkgs-itensor
          pkgs-hphi
          pkgs-quantum-espresso
          pkgs.pkg-config
          pkgs.cmake
        ];
        zshCompEnv = pkgs.buildEnv {
          name = "zsh-comp";
          paths = shell-pkgs;
          pathsToLink = [ "/share/zsh" ];
        };
      in {
        packages.itensor = pkgs-itensor;
        packages.hphi = pkgs-hphi;
        packages.quantum-espresso = pkgs-quantum-espresso;
        devShells.default = pkgs.mkShell rec {
          packages = shell-pkgs;
          ZSH_COMP_FPATH = "${zshCompEnv}/share/zsh/site-functions";
        };
      });
}
