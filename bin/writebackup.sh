#!/bin/ksh
###########################################################################HP##
##
# FILE: 	writebackup.sh
# PRODUCT:	tools
# AUTHOR: 	/^--
# DATE CREATED:	10-Jul-2003
#
###############################################################################
# CONTENTS: 
# Write subsequent backups of passed file(s) with date file extension (format
# '.YYYYMMDD[a-z]' in the same directory as the file itself. The first backup
# file has letter 'a' appended, the next 'b', and so on. 
#	
# REMARKS: 
#	
# REVISION	DATE		REMARKS 
#	0.02	22-Sep-2006	Cleaned up code, renamed to 'writebackup.sh', 
#				added ability to pass in more than one file. 
#	0.01	10-Jul-2003	file creation
###############################################################################
#FILE_SCCS = "@(#)writebackup.sh	0.02	(22-Sep-2006)	tools";

writebackup()
{
    typeset file=$1
    # Check preconditions. 
    if [ ! -r "${file}" -o ! -f "${file}" ]
    then
	print -R >&2 "Error: \"${file}\" is no file or not readable!" 
	return 1
    fi

    # Determine backup file name and do backup. 
    typeset timestamp=`date +%Y%m%d`

    typeset number=97   # letter 'a'
    while [ $number -le 122 ] # until letter 'z'
    do
	# Because the shell cannot increase characters, only add with numbers, we 
	# loop over the ASCII value of the backup letter, then use the desktop 
	# calculator to convert this into the corresponding character. 
	typeset numberchar=`echo ${number}P|dc`
	typeset backupfilename="${file}.${timestamp}${numberchar}"
	if [ -a "${backupfilename}" ]
	then
	    # Current backup letter already exists, try next one. 
	    let number=number+1
	    continue
	fi
	# Found unused backup letter; write backup and return. 
	cp "${file}" "${backupfilename}"
	print -R "Backed up to `basename "${backupfilename}"`"
	return 0
    done

    # All backup letters a-z are already used; report error. 
    print -R >&2 "Ran out of backup file names for file \"${file}\"!"
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

