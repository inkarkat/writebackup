'/**************************************************************************HP**
'**
'* FILE: 	writebackup.vbs
'* PRODUCT:	tools
'* AUTHOR: 	/^--
'* DATE CREATED:    24-Jan-2003
'*
'*******************************************************************************
'* CONTENTS: 
'        Write subsequent backups of the specified file(s) with date file
'        extension (format '.YYYYMMDD[a-z]' in the same directory as the file
'        itself. The first backup file has letter 'a' appended, the next 'b',
'        and so on. 
'
'* REMARKS: 
'       	
'* REVISION	DATE		REMARKS 
'	003	11-Sep-2007	Factored out functions getCurrentDate() and
'				getBackupFilename(). 
'	0.02	22-Sep-2006	Improved error message. 
'	0.01	24-Jan-2003	file creation
'*******************************************************************************
'*FILE_SCCS = "@(#)writebackup.vbs	003	(11-Sep-2007)	tools";

Function getCurrentDate()
'*******************************************************************************
'* PURPOSE:
'	Assemble current date in "yyyymmdd" format; unfortunately, there's no
'	strftime() function, so we have to fill single-digit days and months with
'	leading zero. 
'* ASSUMPTIONS / PRECONDITIONS:
'	none
'* EFFECTS / POSTCONDITIONS:
'	none
'* INPUTS:
'	none
'* RETURN VALUES: 
'	Current date. 
'*******************************************************************************
    Dim currentYear, currentMonth, currentDay
    currentYear = Year( Date )
    currentMonth = Month( Date ) 
    If( Len(currentMonth) = 1 ) Then
	currentMonth = "0" & currentMonth
    End If
    currentDay = Day( Date )
    If( Len(currentDay) = 1 ) Then
	currentDay = "0" & currentDay
    End If

    getCurrentDate = currentYear & currentMonth & currentDay
End Function

Function getBackupFilename( filename )
'*******************************************************************************
'* PURPOSE:
'	Resolve the passed filename into the filename that will be used for the
'	next backup. Path information is retained, the backup extension
'	'YYYYMMDD(a-z)' will be appended. 
'* ASSUMPTIONS / PRECONDITIONS:
'	? List of any external variable, control, or other element whose state affects this procedure.
'* EFFECTS / POSTCONDITIONS:
'	Pops up a MsgBox() if no more backup filenames are available. 
'* INPUTS:
'	filename    Filespec of the original file to be backed up. 
'* RETURN VALUES: 
'	Filespec of the backup file, or Empty if no more backup filenames are
'	available. 
'*******************************************************************************
    Dim fso
    Set fso = CreateObject("Scripting.FileSystemObject")

    Dim currentDate, currentLetter
    currentDate = getCurrentDate()
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
	    getBackupFilename = backupFilename
	    Exit Function
	End If
    Loop Until( currentLetter > "z" )

    ' All 26 possible backup slots (a..z) have already been taken. 
    Call MsgBox( "Ran out of backup file names for file " & Chr(34) & filename & Chr(34) & ".", vbWarning, WScript.ScriptName )
End Function

Sub writebackup( filename )
'*******************************************************************************
'* PURPOSE:
'	Create a backup of the passed file. 
'* ASSUMPTIONS / PRECONDITIONS:
'	passed file exists; otherwise, an error message is shown.
'* EFFECTS / POSTCONDITIONS:
'	Creates a backup copy of the passed file. 
'* INPUTS:
'	filename: path and file name of file to be backuped. 
'* RETURN VALUES: 
'	none
'*******************************************************************************
    Dim fso
    Set fso = CreateObject("Scripting.FileSystemObject")

    ' Check precondition that file exists; otherwise, the rest does not make
    ' sense. 
    If( Not fso.FileExists( filename ) ) Then
	Call MsgBox( "The file " & Chr(34) & filename & Chr(34) & " does not exist.", vbCritical, WScript.ScriptName ) 
	Exit Sub
    End If

    Dim backupFilename
    backupFilename = getBackupFilename( filename )
    If Not IsEmpty( backupFilename ) Then
	Call fso.CopyFile( filename, backupFilename )
    End If
End Sub



'*******************************************************************************
'* PURPOSE:
'	main routine; call the writebackup() function on each passed filename.
'* ASSUMPTIONS / PRECONDITIONS:
'	? List of any external variable, control, or other element whose state affects this procedure.
'* EFFECTS / POSTCONDITIONS:
'	? List of the procedure's effect on each external variable, control, or other element.
'* INPUTS:
'	argc, argv
'* RETURN VALUES: 
'	none
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

