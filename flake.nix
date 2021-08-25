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
    let 
      rustLibTemplate = {
        path = ./templates/rust-lib;
        description = "A rust library setup with a github action";
      };
      overlays = [ (import ./nix/rust-overlay.nix) ];
      packageName = "yatima-nix-utils";
      # This currently breaks purity
      filterRustProject = builtins.filterSource
        (path: type: type != "directory" || builtins.baseNameOf path != "target");
    in
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system overlays;};
      # Get a version of rust as you specify
      getRust = args: import ./nix/rust.nix ({ nixpkgs = pkgs; } // args);
      # This is the version used across projects
      rustDefault = getRust {};

      # Naersk using the default rust version
      naerskDefault = naersk.lib."${system}".override {
        rustc = rustDefault;
        cargo = rustDefault;
      };


      buildRustProject = { naersk ? naerskDefault, ... } @ args: naersk.buildPackage ({
        buildInputs = with pkgs; [ ];
        targets = [ ];
        copyLibs = true;
        remapPathPrefix =
          true; # remove nix store references for a smaller output package
        } // args);

      # Convenient for running tests
      testRustProject = args: buildRustProject ({ doCheck = true; } // args);
    in
    {
      lib = {
        inherit
        getRust
        naerskDefault
        rustDefault
        buildRustProject
        testRustProject
        filterRustProject;
      };
      nixpkgs = pkgs;

      # `nix flake check`
      checks = {
        getRust = getRust {};
        inherit naerskDefault;
      };

      # `nix develop`
      devShell = pkgs.mkShell {
        name = packageName;
        buildInputs = with pkgs; [
          nixpkgs-fmt
          nix-linter
        ];
      };
    }) //
    # Not dependent on system
    {
      defaultTemplate = rustLibTemplate;

      templates = {
        rust-lib = rustLibTemplate;
      };
    };
}
