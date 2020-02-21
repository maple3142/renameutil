import os
import regex
import strformat
import parseopt

var dryrun = false
var silent = false
var args: seq[string] = @[]
var p = initOptParser(commandLineParams())
while true:
  p.next()
  case p.kind
  of cmdEnd: break
  of cmdShortOption, cmdLongOption:
    if p.key == "d" or p.key == "dry-run":
      dryrun = true
    elif p.key == "s" or p.key == "silent":
      silent = true
  of cmdArgument:
    args.add(p.key)


if args.len < 3:
  stderr.writeLine("""Rename Util v0.0.1

Arguments: <replace regex> <target pattern> <directory>
    <replace regex>    A regex to replace from, which is supported by "https://github.com/nitely/nim-regex"
    <target pattern>   Replace target
                       You can use $1, $2, ..., $n to use captured group.
                       But, if you are using bash, please note that you have to escape the dollar sign($) first.
    <directory>        Relative path to the directory containing the files you want to rename.

Flags:
    --dry-run, -d      Dry run (Doesn't actually rename files)
    --silent, -s       Supress output (Doesn't work on error messages)""")
  quit(0)

try:
  let cwd = getCurrentDir()
  let replaceRegex = re(args[0])
  let targetPattern = args[1]
  let directory = joinPath(cwd, args[2])

  if not existsDir(directory):
    stderr.writeLine(fmt"Directory {directory} doesn't exist.")
  for kind, path in walkDir(directory):
    let (head, tail) = splitPath(path)
    let newName = tail.replace(replaceRegex, targetPattern)
    let newPath = joinPath(head, newName)
    if not silent:
      echo fmt"{path} -> {newPath}"
    if not dryrun:
      moveFile(path, newPath)
except RegexError:
  stderr.writeLine(fmt"Invalid regex: {paramStr(1)}")
except OSError:
  stderr.writeLine("Failed to rename files.")
