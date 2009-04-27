#!/bin/bash
#########################################################################/^--##
##
# FILE: 	writebackup.sh
# PRODUCT:	tools
# AUTHOR: 	Ingo Karkat <ingo@karkat.de>
# DATE CREATED:	10-Jul-2003
#
###############################################################################
# CONTENTS: 
#   Write subsequent backups of passed file(s) with a current date file
#   extension (format '.YYYYMMDD[a-z]') in the same directory as the file
#   itself. The first backup of a day has letter 'a' appended, the next 'b', and
#   so on. (Which means that a file can be backed up up to 26 times on any given
#   day.)
#   Directories will be zipped (individually) into an archive file with date
#   file extension. For example, a directory 'foo' will be backed up to
#   'foo.zip.20070911a'. This zip file will only contain the 'foo' directory at
#   its top level; 'foo' itself will contain the entire subtree of the original
#   'foo' directory. 
#   The archiver can be changed; e.g. you could use 'tar' instead of 'zip' by
#   specifying
#	--archive-program "tar cvf" --archive-extension .tar
#	
# DIAGNOSTICS:
#   0	Complete success. 
#   1	Failed to backup any file(s). 
#   2	Partial success; some file(s) could not be backed up. 
#
# REMARKS: 
#	
# Copyright: (C) 2007-2009 by Ingo Karkat
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License.
#   See http://www.gnu.org/copyleft/gpl.txt 
#
# REVISION	DATE		REMARKS 
#   1.10.003	28-Apr-2009	Converted from Korn shell to Bash script. 
#   1.10.002	05-Dec-2007	Factored out function getBackupFilename(). 
#				Added handling of directories. 
#   1.00.001	10-Mar-2007	Added copyright, prepared for publishing. 
#	0.02	22-Sep-2006	Cleaned up code, renamed to 'writebackup.sh', 
#				added ability to pass in more than one file. 
#	0.01	10-Jul-2003	file creation
###############################################################################
#FILE_SCCS = "@(#)writebackup.sh	1.10.003	(28-Apr-2009)	tools";

shopt -qu xpg_echo

archiveProgram='zip -9 -r'
archiveExtension='.zip'

archiveAndBackup()
{
    local -r dirspec=${1%/}

    local -r archiveDirBasename=$(basename -- "${dirspec}")
    local -r baseDirspec=$(dirname -- "${dirspec}")
    local -r backupFilespec=$(basename -- "$(getBackupFilename "${dirspec}${archiveExtension}")")
    [ ! "${backupFilespec}" ] && return 1

    echo "Archiving ${dirspec}..."
    local -r savedCwd=$(pwd)
    cd "${baseDirspec}" && eval "${archiveProgram}" \"${backupFilespec}\" \"${archiveDirBasename}/\"
    if [ $? -eq 0 ]; then
	echo "Backed up to $(basename -- "${backupFilespec}")"
	cd "${savedCwd}" && return 0 || return 1
    else
	echo >&2 "Could not create archive! "
	cd "${savedCwd}"
	return 1
    fi
}

getBackupFilename()
###############################################################################
# PURPOSE:
#   Resolve the passed filename into the filename that will be used for the next
#   backup. Path information is retained, the backup extension 'YYYYMMDD(a-z)'
#   will be appended. 
# ASSUMPTIONS / PRECONDITIONS:
#   ? List of any external variable, control, or other element whose state affects this procedure.
# EFFECTS / POSTCONDITIONS:
#   Prints error message to stderr. 
# INPUTS:
#   filespec    Filespec of the original file to be backed up. 
# RETURN VALUES:
#   Filespec of the backup file to stdout, or nothing if no more backup
#   filenames are available. 
#   0 on success, 1 on failure
###############################################################################
{
    local -r filespec=$1

    # Determine backup file name. 
    local number=97   # letter 'a'
    while [ $number -le 122 ] # until letter 'z'
    do
	# Because the shell cannot increase characters, only add with numbers, we 
	# loop over the ASCII value of the backup letter, then use the desktop 
	# calculator to convert this into the corresponding character. 
	local numberchar=$(echo ${number}P|dc)
	local backupFilespec="${filespec}.${timestamp}${numberchar}"
	if [ -a "${backupFilespec}" ]; then
	    # Current backup letter already exists, try next one. 
	    let number+=1
	    continue
	fi
	# Found unused backup letter. 
	echo "${backupFilespec}"
	return 0
    done

    # All backup letters a-z are already used; do not return a backup filename. 
    echo >&2 "Ran out of backup file names for file \"${filespec}\"!"
    return 1
}

writebackup()
###############################################################################
# PURPOSE:
#   Create a backup of the passed file or directory. 
# ASSUMPTIONS / PRECONDITIONS:
#   Passed file or directory exists; otherwise, an error message is printed. 
# EFFECTS / POSTCONDITIONS:
#   Creates a backup copy of the passed file or directory. 
# INPUTS:
#   spec    path and name
# RETURN VALUES:
#   0 on success, 1 on failure
###############################################################################
{
    local -r spec=$1

    if [ -f "${spec}" ]; then
	if [ ! -r "${spec}" ]; then
	    echo >&2 "Error: \"${spec}\" is not readable!" 
	    return 1
	fi

	local -r backupFilespec=$(getBackupFilename "${spec}")
	if [ "${backupFilespec}" ]; then
	    cp "${spec}" "${backupFilespec}"
	    echo "Backed up to $(basename -- "${backupFilespec}")"
	    return 0
	else
	    return 1
	fi
    elif [ -d "${spec}" ]; then
	if [ ! -r "${spec}" -o ! -x "${spec}" ]; then
	    echo >&2 "Error: \"${spec}\" is not accessible!" 
	    return 1
	fi
	archiveAndBackup "${spec}" || return 1
    else
	echo >&2 "Error: \"${spec}\" does not exist!" 
	return 1
    fi
}

printUsage()
{
    echo >&2 "Usage: \"$(basename "$1")\" [--archive-program \"zip -9 -r\" --archive-extension .zip] file [,...] [--help|-h|-?]"
}

#------------------------------------------------------------------------------

while [ $# -ne 0 ]
do
    case "$1" in
	--help|-h|-\?)		shift; printUsage "$0"; exit 1;;
	--archive-program)	shift; archiveProgram="$1"; shift;;
	--archive-extension)	shift; archiveExtension="$1"; shift;;
	--)			shift; break;;
	*)			break;;
    esac
done
if [ $# -eq 0 ]; then
    printUsage "$0"
    exit 1
fi

readonly timestamp=$(date +%Y%m%d)
isSuccess=""
isFailure=""

while [ $# -ne 0 ]
do
    writebackup "$1" && isSuccess="true" || isFailure="true"
    shift
done

if [ "${isFailure}" ]; then
    [ "${isSuccess}" ] && exit 2 || exit 1
fi

