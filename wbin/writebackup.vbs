'/************************************************************************/^--**
'**
'* FILE: 	writebackup.vbs
'* PRODUCT:	tools
'* AUTHOR: 	Ingo Karkat <ingo@karkat.de>
'* DATE CREATED:24-Jan-2003
'*
'*******************************************************************************
'* CONTENTS: 
'   Write subsequent backups of passed file(s) with a current date file
'   extension (format '.YYYYMMDD[a-z]') in the same directory as the file
'   itself. The first backup of a day has letter 'a' appended, the next 'b', and
'   so on. (Which means that a file can be backed up up to 26 times on any given
'   day.)
'
'* REMARKS: 
'
' Copyright: (C) 2007 by Ingo Karkat
'   This program is free software; you can redistribute it and/or modify it
'   under the terms of the GNU General Public License.
'   See http://www.gnu.org/copyleft/gpl.txt 
'
'* REVISION	DATE		REMARKS 
'   1.00.001	10-Mar-2007	Added copyright, prepared for publishing. 
'	0.01	24-Jan-2003	file creation
'*******************************************************************************
'*FILE_SCCS = "@(#)writebackup.vbs	1.00.001	(10-Mar-2007)	tools";

Sub writebackup( filename )
'*******************************************************************************
'* PURPOSE:
'    Create a backup of the passed file. 
'* ASSUMPTIONS / PRECONDITIONS:
'    passed file exists; otherwise, an error message is shown.
'* EFFECTS / POSTCONDITIONS:
'    Creates a backup copy of the passed file. 
'* INPUTS:
'    filename: path and file name of file to be backuped. 
'* RETURN VALUES: 
'    none
'*******************************************************************************
    Dim fso
    Set fso = CreateObject("Scripting.FileSystemObject")

    ' Check precondition that file exists; otherwise, the rest does not make
    ' sense. 
    If( Not fso.FileExists( filename ) ) Then
	Call MsgBox( "The file " & Chr(34) & filename & Chr(34) & " does not exist.", vbCritical, WScript.ScriptName ) 
	Exit Sub
    End If

    ' Assemble current date in "yyyymmdd" format; unfortunately, there's no
    ' strftime() function, so we have to fill single-digit days and months with
    ' leading zero. 
    Dim currentYear, currentMonth, currentDay, currentDate, currentLetter
    currentYear = Year( Date )
    currentMonth = Month( Date ) 
    If( Len(currentMonth) = 1 ) Then
	currentMonth = "0" & currentMonth
    End If
    currentDay = Day( Date )
    If( Len(currentDay) = 1 ) Then
	currentDay = "0" & currentDay
    End If

    currentDate = currentYear & currentMonth & currentDay
    currentLetter = "a"

    ' Perform backup copy with next available letter. 
    Dim backupFilename
    Do
	backupFilename = filename & "." & currentDate & currentLetter
	If( fso.FileExists( backupFilename ) ) Then
	    ' To increment, we need to convert letter to ASCII and back. 
	    currentLetter = Chr( Asc(currentLetter) + 1 )
	Else
	    ''''D MsgBox filename & vbCrLf & backupFilename
	    Call fso.CopyFile( filename, backupFilename )
	    Exit Sub
	End If
	
    Loop Until( currentLetter > "z" )

    ' All 26 possible backup slots (a..z) have already been taken. 
    Call MsgBox( "Ran out of backup file names for file " & Chr(34) & filename & Chr(34) & "!", vbWarning, WScript.ScriptName )
End Sub



'*******************************************************************************
'* PURPOSE:
'    main routine; call the writebackup() function on each passed filename.
'* ASSUMPTIONS / PRECONDITIONS:
'    ? List of any external variable, control, or other element whose state affects this procedure.
'* EFFECTS / POSTCONDITIONS:
'    ? List of the procedure's effect on each external variable, control, or other element.
'* INPUTS:
'    argc, argv
'* RETURN VALUES: 
'    none
'*******************************************************************************
Dim objArgs

Set objArgs = WScript.Arguments

If( objArgs.Count < 1 ) Then
    WScript.Echo( "writebackup: write backup of passed files with date file extension. " )
    WScript.Echo( "Syntax: " & WScript.ScriptName & " <filename> [,...]" )
    WScript.Quit 1
End If

' Process each passed filename
Dim i
For i = 0 to objArgs.Count - 1
    Call writebackup( objArgs( i ) )
Next

