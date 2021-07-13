{
  description = "Nix utils used across yatima inc projects.";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    naersk.url = "github:nmattia/naersk";
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , naersk
    }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      overlays = [ (import ./nix/rust-overlay.nix) ];
      pkgs = import nixpkgs { inherit system overlays;};
      # Get a version of rust as you specify
      getRust = args: import ./nix/rust.nix { nixpkgs = pkgs; } // args;
      # This is the version used across projects
      rustDefault = getRust {};

      # Naersk using the default rust version
      naerskDefault = naersk.lib."${system}".override {
        rustc = rustDefault;
        cargo = rustDefault;
      };

      packageName = "yatima-nix-utils";
      filterRustProject = builtins.filterSource
        (path: type: type != "directory" || builtins.baseNameOf path != "target");


      buildRustProject = { naersk ? naerskDefault, ... } @ args: naersk.buildPackage {
        buildInputs = with pkgs; [ ];
        targets = [ ];
        copyLibs = true;
        remapPathPrefix =
          true; # remove nix store references for a smaller output package
      } // args;

      # Convenient for running tests
      testRustProject = args: buildRustProject { doCheck = true; } // args;
    in
    {
      lib = {
        inherit
          naerskDefault
          rustDefault
          buildRustProject
          testRustProject
          filterRustProject;
      };
      nixpkgs = pkgs;

      # `nix develop`
      devShell = pkgs.mkShell {
        name = packageName;
        buildInputs = with pkgs; [
          nixpkgs-fmt
          nix-linter
        ];
      };
    });
}
