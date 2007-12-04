#!/bin/ksh
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
#	
# REMARKS: 
#	
# Copyright: (C) 2007 by Ingo Karkat
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License.
#   See http://www.gnu.org/copyleft/gpl.txt 
#
# REVISION	DATE		REMARKS 
#   1.00.001	10-Mar-2007	Added copyright, prepared for publishing. 
#	0.02	22-Sep-2006	Cleaned up code, renamed to 'writebackup.sh', 
#				added ability to pass in more than one file. 
#	0.01	10-Jul-2003	file creation
###############################################################################
#FILE_SCCS = "@(#)writebackup.sh	1.00.001	(10-Mar-2007)	tools";

archiveProgram="zip -9 -r"
archiveExtension=".zip"

archiveAndBackup()
{
    typeset dirspec=${1%/}

    typeset archiveDirBasename=$(basename -- "${dirspec}")
    typeset baseDirspec=$(dirname -- "${dirspec}")
    typeset backupFilespec=$(basename -- "$(getBackupFilename "${dirspec}${archiveExtension}")")
    [ ! "${backupFilespec}" ] && return 1

    print -R "Archiving ${dirspec}..."
    typeset savedCwd=$(pwd)
    cd "${baseDirspec}" && eval "${archiveProgram}" "${backupFilespec}" "${archiveDirBasename}/" # > /dev/null
    if [ $? -eq 0 ]
    then
	print -R "Backed up to $(basename -- "${backupFilespec}")"
    else
	print -R >&2 "Could not create archive! "
    fi

    cd "${savedCwd}"
}

getBackupFilename()
{
    typeset filespec=$1

    # Determine backup file name. 
    typeset timestamp=$(date +%Y%m%d)

    typeset number=97   # letter 'a'
    while [ $number -le 122 ] # until letter 'z'
    do
	# Because the shell cannot increase characters, only add with numbers, we 
	# loop over the ASCII value of the backup letter, then use the desktop 
	# calculator to convert this into the corresponding character. 
	typeset numberchar=$(echo ${number}P|dc)
	typeset backupFilespec="${filespec}.${timestamp}${numberchar}"
	if [ -a "${backupFilespec}" ]
	then
	    # Current backup letter already exists, try next one. 
	    let number=number+1
	    continue
	fi
	# Found unused backup letter. 
	print -R "${backupFilespec}"
	return 0
    done

    # All backup letters a-z are already used; do not return a backup filename. 
    print -R >&2 "Ran out of backup file names for file \"${filespec}\"!"
    return 1
}

writebackup()
{
    typeset spec=$1

    if [ -f "${spec}" ]
    then
	if [ ! -r "${spec}" ]
	then
	    print -R >&2 "Error: \"${spec}\" is not readable!" 
	    return 1
	fi

	typeset backupFilespec=$(getBackupFilename "${spec}")
	if [ "${backupFilespec}" ]
	then
	    cp "${spec}" "${backupFilespec}"
	    print -R "Backed up to $(basename -- "${backupFilespec}")"
	    return 0
	else
	    return 1
	fi
    elif [ -d "${spec}" ]
    then
	if [ ! -r "${spec}" -o ! -x "${spec}" ]
	then
	    print -R >&2 "Error: \"${spec}\" is not accessible!" 
	    return 1
	fi
	archiveAndBackup "${spec}" || return 1
    else
	print -R >&2 "Error: \"${spec}\" does not exist!" 
	return 1
    fi
}

printUsage()
{
    echo >&2 "Usage: \"$(basename "$1")\" file [,...] [--help|-h|-?]"
}

while [ $# -ne 0 ]
do
    case "$1" in
	--help|-h|-\?)	shift; printUsage "$0"; exit 1;;
	--)		shift; break;;
	*)		break;;
    esac
done
if [ $# -eq 0 ]
then
    printUsage "$0"
    exit 1
fi

while [ $# -ne 0 ]
do
    writebackup "$1"
    shift
done

