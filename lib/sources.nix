# This `lib` module provides a mechanism for creating source filters from a
# composable list of composable functions.
# This is different from `lib.cleanSourceWith` in that it does not require the
# user to write a recursive call to accomplish the same thing.
# Additionally, each composable filter is aware of the `sourceRoot`, and can
# compare the `path` of each recursive file entry to it.
lib: _:
let
  # A factory for the function passed to `builtins.filterSource`.
  # This takes a `path` and a `type` for each entry from `builtins.readDir`.
  sourceFilter = fn: sourceRoot: name: type:
    let entry = lib.path.mkDirEntry sourceRoot name type;
    in if builtins.functionArgs fn == { } then
      fn entry
    else
      lib.trivial.applyAutoArgs fn entry;

  # Compose multiple filters into one, suitable for `lib.cleanSourceWith`.
  # The first argument is the source root, and the second is a list of filters.
  # The filters are expected to take the source root as the first argument,
  # which means this function is not compatible with `lib.cleanSourceFilter`.
  # Compose the other pre-made filter functions with this one.
  mkSourceFilter = sourceRoot: filters: name: type:
    builtins.all (fn: fn sourceRoot name type) filters;

  # Removes entries with `unknown` type, removes object files, removes VCS files,
  # removes editor files, and paths common to Nix flakes.
  defaultSourceFilter = sourceRoot:
    mkSourceFilter sourceRoot [
      unknownSourceFilter
      objectSourceFilter
      vcsSourceFilter
      editorSourceFilter
      flakeSourceFilter
    ];

  # Filter out sockets and other types of files we can't have in the store.
  unknownSourceFilter = sourceFilter ({ type }: type != "unknown");

  objectSourceFilter = sourceFilter ({ isFile, extension }:
    !(isFile && builtins.elem extension [ ".o" ".so" ]));

  # Removes directories for version control systems at any
  # level of nested paths.
  vcsSourceFilter = sourceFilter ({ baseName, isDir }:
    !(
      # Git
      (isDir && baseName == ".git")
      # Apache Subversion
      || (isDir && baseName == ".svn")
      # Mercurial
      || (isDir && baseName == ".hg")
      # Concurrent Versions System
      || (isDir && baseName == "CVS")));

  editorSourceFilter = sourceFilter ({ baseName, isDir }:
    !(
      # Visual Studio Code
      (isDir && baseName == ".vscode")
      # JetBrains
      || (isDir && baseName == ".idea")
      # Eclipse
      || (isDir && baseName == ".eclipse")
      # Backup / swap files
      || (lib.hasSuffix "~" baseName)
      || (builtins.match "^\\.sw[a-z]$" baseName != null)
      || (builtins.match "^\\..*\\.sw[a-z]$" baseName != null)));

  flakeSourceFilter = sourceFilter
    ({ baseName, atRoot, relPath, isDir, isFile, isLink, extension }:
      !(
        # A very common convention is to have a directory for Nix files.
        (atRoot && isDir && baseName == "nix")
        # Also don't want any Nix files in the root.
        # Others might be examples or included,
        # if a project is properly organized they won't be anywhere besides
        # the root anyway.
        || (atRoot && isFile && extension == ".nix")
        # And of course, the `flake.lock`.
        || (atRoot && isFile && baseName == "flake.lock")
        # Filter out `nix-build` result symlinks.
        || (isLink && lib.hasPrefix "result" baseName)));

  # Removes directories that Cargo generates.
  # This filter is careful and will only remove matching names
  # in the source root, but not similarly-named nested paths.
  rustSourceFilter = sourceFilter
    ({ baseName, atRoot, isDir }: !(atRoot && isDir && baseName == "target"));

  # cleanSourceFilter = name: type:
  #   let baseName = baseNameOf (toString name);
  #   in !(
  #     # Filter out version control software files/directories
  #     (baseName == ".git" || type == "directory"
  #       && (baseName == ".svn" || baseName == "CVS" || baseName == ".hg")) ||
  #     # Filter out editor backup / swap files.
  #     lib.hasSuffix "~" baseName || builtins.match "^\\.sw[a-z]$" baseName
  #     != null || builtins.match "^\\..*\\.sw[a-z]$" baseName != null ||

  #     # Filter out generates files.
  #     lib.hasSuffix ".o" baseName || lib.hasSuffix ".so" baseName ||
  #     # Filter out nix-build result symlinks
  #     (type == "symlink" && lib.hasPrefix "result" baseName) ||
  #     # Filter out sockets and other types of files we can't have in the store.
  #     (type == "unknown"));
in {
  inherit sourceFilter mkSourceFilter defaultSourceFilter unknownSourceFilter
    objectSourceFilter vcsSourceFilter editorSourceFilter flakeSourceFilter
    rustSourceFilter;
}
