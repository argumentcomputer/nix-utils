{
  description = throw "TODO Description";
  inputs = {
    nixpkgs.url = github:nixos/nixpkgs;
    flake-utils = {
      url = github:numtide/flake-utils;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    naersk = {
      url = github:nix-community/naersk;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    utils = {
      url = github:yatima-inc/nix-utils;
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.naersk.follows = "naersk";
    };
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , utils
    , naersk
    }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      lib = utils.lib.${system};
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (lib) buildRustProject testRustProject rustDefault filterRustProject;
      rust = rustDefault;
      crateName = throw "TODO my-crate";
      root = ./.;
      project = buildRustProject { inherit root; };
    in
    {
      packages.${crateName} = project;
      checks.${crateName} = testRustProject { inherit root; };

      defaultPackage = self.packages.${system}.${crateName};

      # To run with `nix run`
      apps.${crateName} = flake-utils.lib.mkApp {
        drv = project;
      };

      # `nix develop`
      devShell = pkgs.mkShell {
        inputsFrom = builtins.attrValues self.packages.${system};
        nativeBuildInputs = [ rust ];
        buildInputs = with pkgs; [
          rust-analyzer
          clippy
          rustfmt
        ];
      };
    });
}
