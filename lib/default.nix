# Bootstrap the library overlay with primitive functions only,
# using `lib` or `lib0` here would result in infinite recursion.
let
  pipe = builtins.foldl' (x: f: f x);
  mapAttrs' = f: set:
    builtins.listToAttrs
    (map (attr: f attr set.${attr}) (builtins.attrNames set));

  overlayAttrs = self: super:
    mapAttrs' (name: overlay: rec {
      inherit name;
      value = (super.${name} or { }) // overlay self super;
    });

  # Creates a new overlay that has applied imports from `dir` and merges
  # them with their respective scopes.
  mergeLib = dir: self: super:
    pipe dir [
      builtins.readDir
      (attrs: removeAttrs attrs [ "default.nix" ])
      (mapAttrs' (file: _: {
        name = baseNameOf file;
        value = import "${dir}/${file}";
      }))
      (overlayAttrs self super)
    ];
in mergeLib ./.
