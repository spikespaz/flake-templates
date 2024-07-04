# Bootstrap the library overlay with primitive functions only,
# using `lib` or `lib0` here would result in infinite recursion.
let
  pipe = builtins.foldl' (x: f: f x);
  mapAttrs' = f: set:
    builtins.listToAttrs
    (map (attr: f attr set.${attr}) (builtins.attrNames set));

  overlayAttrs = attrs: self: super:
    super // (mapAttrs' (name: overlay: rec {
      inherit name;
      value = (super.${name} or { }) // overlay self super;
    }) attrs);

  # Creates a new overlay that has applied imports from `dir` and merges
  # them with their respective scopes.
  stripDotNix = file: builtins.elemAt (builtins.match "(.*).nix" file) 0;
  mergeLib = dir: self: super:
    pipe dir [
      builtins.readDir
      (attrs: removeAttrs attrs [ "default.nix" ])
      (mapAttrs' (file: _: {
        name = stripDotNix file;
        value = import "${dir}/${file}";
      }))
      (attrs: overlayAttrs attrs self super)
    ];
in mergeLib ./.
