{
  description = "Nix utils used across yatima inc projects.";
  inputs = {
    nixpkgs.url = github:nixos/nixpkgs;
    flake-utils = {
      url = github:numtide/flake-utils;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    naersk = {
      url = github:yatima-inc/naersk;
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , naersk
    }:
    let
      templates = import ./templates.nix { };
      customLib = import ./nix/lib.nix { inherit (nixpkgs) lib; };
      generalLib = flake-utils.lib // customLib;
      overlays = [ (import ./nix/rust-overlay.nix) ];
      packageName = "yatima-nix-utils";
      # This currently breaks purity
      filterRustProject = builtins.filterSource
        (path: type: type != "directory" || builtins.baseNameOf path != "target");
      # Each system
      eachSystem = flake-utils.lib.eachDefaultSystem
        (system:
          let
            pkgs = import nixpkgs { inherit system overlays; };
            lib = pkgs.lib // generalLib;
            buildCLib = import ./nix/buildCLib.nix { pkgs = nixpkgs; inherit system lib; };
            # Get a version of rust as you specify
            getRust = args: import ./nix/rust.nix ({
              nixpkgs = pkgs;
            } // args);
            # This is the version used across projects
            rustDefault = getRust { };
            # Get a naersk with the input rust version
            naerskWithRust = rust: naersk.lib."${system}".override {
              rustc = rust;
              cargo = rust;
            };
            # Naersk using the default rust version
            naerskDefault = naerskWithRust rustDefault;
            buildRustProject = pkgs.makeOverridable ({ rust ? rustDefault, naersk ? naerskWithRust rust, ... } @ args: naersk.buildPackage ({
              buildInputs = with pkgs; [ ];
              targets = [ ];
              copyLibs = true;
              remapPathPrefix =
                true; # remove nix store references for a smaller output package
            } // args));

            # Convenient for running tests
            testRustProject = args: buildRustProject ({ doCheck = true; } // args);
          in
          {
            lib = lib // {
              inherit
                # C functions
                buildCLib
                # Rust functions
                getRust
                naerskDefault
                naerskWithRust
                rustDefault
                buildRustProject
                testRustProject
                filterRustProject;
            };

            # `nix flake check`
            checks =
              let
                cBuild = buildCLib {
                  name = "buildCLib-test";
                  src = ./templates/c-lib/src;
                };
              in
              {
                getRust = getRust { };
                inherit cBuild;
                cBuild-shared = cBuild.sharedLib;
              };

            # `nix develop`
            devShell = pkgs.mkShell {
              name = packageName;
              buildInputs = with pkgs; [
                nixpkgs-fmt
                nix-linter
              ];
            };
          });
    in
    # Not dependent on system
    eachSystem // {
      lib = eachSystem.lib // generalLib;
      defaultTemplate = templates.rustLibTemplate;
      inherit templates;
    };
}
