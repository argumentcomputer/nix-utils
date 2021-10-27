# A very simple setup to compile C and C++ code
{ pkgs, system }:
with builtins;
let
  inherit (pkgs) stdenv lib;
  joinArgs = lib.concatStringsSep " ";
  protoBuildCLib = lib.makeOverridable
    ({ name
     , src
     , static ? false
     , libExtension ? if static then "a" else "so"
     , libName ? "lib${name}.${libExtension}"
     , cc ? stdenv.cc
       # A function that 
     , updateCCOptions ? a: a
     , sourceFiles ? [ "*.c" ]
     , debug ? false
     , extraDrvArgs ? {}
     }:
      let
        defaultOptions = [ "-Wall" "-pedantic" "-O3" (if debug then "-ggdb" else "") ];
        commonCCOptions = updateCCOptions defaultOptions;
        buildSteps =
          if static then
            [
              "${cc}/bin/cc ${commonCCOptions} -c ${joinArgs sourceFiles}"
              "ar rcs ${libName} ${objectFile}"

            ] else
            [
              "${cc}/bin/cc ${commonCCOptions} -shared -o ${libName} ${sourceFiles}"
            ];
      in
      pkgs.stdenv.mkDerivation ({
        inherit src system;
        name = libName;
        buildInputs = with pkgs; [ cc clib ] ++ staticLibDeps;
        NIX_DEBUG = 1;
        buildPhase = pkgs.lib.concatStringsSep "\n" buildSteps;
        installPhase = ''
          mkdir -p $out
          cp ${libName} $out
        '';
      } // extraDrvArgs));

  # type: {a = b;} -> (a -> b -> c) -> [c]
  forEachRow = attrset: f: lib.zipListsWith f (attrNames attrset) (attrValues attrset);
  forEachRowJoin = attrset: f: lib.foldl (acc: c: acc // c) { } (forEachRow attrset f);
  # Extend an overridable function with the given overrideArgs.
  extendOverridableFn = (f: overrideArgs: args:
    let
      self = f args;
      newProps = forEachRowJoin overrideArgs (name: attrs: { ${name} = self.override attrs; });
    in
    self // newProps
  );
  # Property extensions. Each generation inherits the properties of the last.
  propertyGenerations = [
    {
      debug = { debug = true; };
    }
    {
      staticLib = {
        static = true;
      };
      sharedLib = {
        static = false;
      };
    }
  ];

  # Add additional properties in sequence
  buildCLib = lib.foldl extendOverridableFn protoBuildCLib propertyGenerations;
in
buildCLib
