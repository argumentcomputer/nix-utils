# Custom library functions
{ lib }:
with builtins;
{
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
}
