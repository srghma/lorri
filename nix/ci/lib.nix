{ pkgs, writeExecline }:
let
  # Write commands to script which aborts immediately if a command is not successful.
  # The status of the unsuccessful command is returned.
  allCommandsSucceed = name: commands: pkgs.lib.pipe commands [
    (pkgs.lib.concatMap (cmd: [ "if" [ cmd ] ]))
    (writeExecline name {})
  ];

  # Takes a `mode` string and produces a script,
  # which modifies PATH given by $1 and execs into the rest of argv.
  # `mode`s:
  #   "set": overwrite PATH, set it to $1
  #   "append": append the given $1 to PATH
  #   "prepend": prepend the given $1 to PATH
  pathAdd = mode:
    let exec = [ "exec" "$@" ];
        importPath = [ "importas" "PATH" "PATH" ];
        set = [ "export" "PATH" "$1" ] ++ exec;
        append = importPath ++ [ "export" "PATH" ''''${PATH}:''${1}'' ] ++ exec;
        prepend = importPath ++ [ "export" "PATH" ''''${1}:''${PATH}'' ] ++ exec;
    in writeExecline "PATH_${mode}" { readNArgs = 1; }
        (if    mode == "set"     then set
        else if mode == "append" then append
        else if mode == "prepend" then prepend
        else abort "don’t know mode ${mode}");

  # Specialized pathAdd execline that prepends the `/bin` directories
  # of a list of (store) paths to PATH.
  pathPrependBins = paths: [ (pathAdd "prepend") (pkgs.lib.makeBinPath paths) ];

in {
  inherit
    allCommandsSucceed
    pathAdd pathPrependBins;
}
