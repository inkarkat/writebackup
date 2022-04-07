# writebackup

_Write subsequent backups of the passed file(s) with a `.YYYYMMDD[a-z]` file extension as a primitive, small and self-contained alternative to revision control systems._

Implemented in _VBScript_ and _Bash_ (but only the latter is still actively maintained).

This is a poor man's revision control system, a primitive alternative to CVS, RCS, Subversion, etc., which works with no additional software and almost any file system. An importer can create a Git repository from backups.

Directories will be zipped (individually) into an archive file with date file extension.

### Dependencies

* Bash
* `cp`
* for archives: `readlink`, `zip` (or other archive tool)

### Installation

The `./bin` subdirectory (`./wbin` for Windows) is supposed to be added to `PATH`.
