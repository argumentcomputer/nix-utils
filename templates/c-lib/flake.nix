{
  description = throw "TODO Description";
  inputs = {
    nixpkgs.url = github:nixos/nixpkgs;
    flake-utils = {
      url = github:numtide/flake-utils;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    utils = {
      url = github:yatima-inc/nix-utils;
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , utils
    }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      lib = utils.lib.${system};
      pkgs = import nixpkgs { inherit system; };
      inherit (lib) buildCLib;
      name = throw "TODO my-crate";
      src = ./src;
      project = buildCLib { inherit name src; };
    in
    {
      packages.${name} = project;
      checks.${name} = testRustProject { inherit root; };

      defaultPackage = self.packages.${system}.${name};

      # To run with `nix run`
      apps.${name} = flake-utils.lib.mkApp {
        drv = project;
      };

      # `nix develop`
      devShell = pkgs.mkShell {
        inputsFrom = builtins.attrValues self.packages.${system};
        nativeBuildInputs = [ ];
        buildInputs = with pkgs; [
        ];
      };
    });
}
