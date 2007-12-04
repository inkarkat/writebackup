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
'   Directories will be zipped (individually) into an archive file with date
'   file extension. For example, a directory 'foo' will be backed up to
'   'foo.zip.20070911a'. This zip file will only contain the 'foo' directory at
'   its top level; 'foo' itself will contain the entire subtree of the original
'   'foo' directory (including system and hidden files). 
'
'* DEPENDENCIES: 
'   Requires the 'zip.exe' command-line utility if you want to backup
'   directories. This utility is part of the Win32 port of the GNU Unix
'   utilities and can be downloaded from http://unxutils.sourceforge.net/
'   
'* REMARKS: 
'
' Copyright: (C) 2007 by Ingo Karkat
'   This program is free software; you can redistribute it and/or modify it
'   under the terms of the GNU General Public License.
'   See http://www.gnu.org/copyleft/gpl.txt 
'
'* REVISION	DATE		REMARKS 
'   1.10.003	11-Sep-2007	Factored out functions getCurrentDate() and
'				getBackupFilename(). 
'				Added handling of directories with class
'				ZipArchiver. 
'				Factored out scattered MsgBox() calls; now,
'				errors are raised and caught in the main
'				function, which then prints the Err.Description
'				via MsgBox(). 
'   1.00.001	10-Mar-2007	Added copyright, prepared for publishing. 
'	0.02	22-Sep-2006	Improved error message. 
'	0.01	24-Jan-2003	file creation
'*******************************************************************************
'*FILE_SCCS = "@(#)writebackup.vbs	1.10.003	(11-Sep-2007)	tools";

Dim ERROR_NO_MORE_FILENAMES : ERROR_NO_MORE_FILENAMES = vbObjectError + 1000
Dim ERROR_NOT_EXISTING : ERROR_NOT_EXISTING = vbObjectError + 1001
Dim ERROR_IN_ARCHIVER : ERROR_IN_ARCHIVER = vbObjectError + 1002

'------------------------------------------------------------------------------
Class ZipArchiver
    Public Sub archive( dirspec )
	Dim fso, archiveDirspec, archiveDirBasename, baseDirspec
	Set fso = CreateObject("Scripting.FileSystemObject")
	archiveDirspec = fso.GetAbsolutePathName( fso.GetFolder( dirspec ) )
	archiveDirBasename = fso.GetBaseName( archiveDirspec )
	baseDirspec = fso.GetParentFolderName( archiveDirspec )

	Dim backupFilespec : backupFilespec = getBackupFilename( archiveDirspec & ".zip" )
	Const zipProgram = "zip"
	Const zipArguments = "-9 -S -r"
	' Highest compression, include system and hidden files, recurse into
	' directories

	Dim zipCommand : zipCommand = "cmd /C pushd " & Chr(34) & baseDirspec & Chr(34) & " && " & zipProgram & " " & zipArguments & " " & Chr(34) & backupFilespec & Chr(34) & " " & Chr(34) & archiveDirBasename & Chr(34)
	' This will raise an error is the Windows shell cannot be found. (We do
	' nothing about that.)
	' If the zipProgram is not found, the shell will exit with return code
	' 1. 

	''''D WScript.Echo zipCommand

	Dim WshShell : Set WshShell = CreateObject("WScript.Shell")
	Dim returnCode : returnCode = WshShell.Run( zipCommand, 7, True )
	If returnCode <> 0 Then
	    Dim reason
	    On Error Resume Next    ' Here, the zipProgram is invoked directly, not through the shell. If the zipProgram isn't found, WshShell.Run() raises an error, which we have to catch. 
	    If returnCode = 1 And WshShell.Run( zipProgram, 7, True ) <> 0 Then
		reason = "The '" & zipProgram & "' program could not be found in the PATH. "
	    Else
		Select Case returnCode
		    Case 10   reason = "zip encountered an error while using a temp file. "
		    Case 11   reason = "read or seek error. "
		    Case 12   reason = "zip has nothing to do. "
		    Case 13   reason = "missing or empty zip file. "
		    Case 14   reason = "error writing to a file. "
		    Case 15   reason = "zip was unable to create a file to write to. "
		    Case 16   reason = "bad command line parameters. "
		    Case 18   reason = "zip could not open a specified file to read. "
		    Case Else reason = "Unknown reason, error code " & returnCode
		End Select
	    End If
	    Call Err.Raise( ERROR_IN_ARCHIVER, "ZipArchiver.archive", "Could not create archive: " & reason )
	End If
    End Sub
End Class

'------------------------------------------------------------------------------

Function getCurrentDate()
'*******************************************************************************
'* PURPOSE:
'   Assemble current date in "yyyymmdd" format; unfortunately, there's no
'   strftime() function, so we have to fill single-digit days and months with
'   leading zero. 
'* ASSUMPTIONS / PRECONDITIONS:
'   none
'* EFFECTS / POSTCONDITIONS:
'   none
'* INPUTS:
'   none
'* RETURN VALUES: 
'   Current date. 
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
'   Resolve the passed filename into the filename that will be used for the next
'   backup. Path information is retained, the backup extension 'YYYYMMDD(a-z)'
'   will be appended. 
'* ASSUMPTIONS / PRECONDITIONS:
'   ? List of any external variable, control, or other element whose state affects this procedure.
'* EFFECTS / POSTCONDITIONS:
'
'* INPUTS:
'   filename    Filespec of the original file to be backed up. 
'* RETURN VALUES: 
'   Filespec of the backup file, or
'   if no more backup filenames are available, raises error number
'   ERROR_NO_MORE_FILENAMES and returns Empty. 
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
	    ''''D WScript.Echo filename & vbCrLf & backupFilename
	    getBackupFilename = backupFilename
	    Exit Function
	End If
    Loop Until( currentLetter > "z" )

    ' All 26 possible backup slots (a..z) have already been taken. 
    Call Err.Raise( ERROR_NO_MORE_FILENAMES, "getBackupFilename", "Ran out of backup file names for file " & Chr(34) & filename & Chr(34) & "! " )
End Function

Sub writebackup( filename )
'*******************************************************************************
'* PURPOSE:
'   Create a backup of the passed file. 
'* ASSUMPTIONS / PRECONDITIONS:
'   passed file exists; otherwise, an error message is shown.
'* EFFECTS / POSTCONDITIONS:
'   Creates a backup copy of the passed file. 
'* INPUTS:
'   filename: path and file name of file to be backuped. 
'* RETURN VALUES: 
'   none
'   Raises ERROR_NOT_EXISTING if filename does not exist. 
'*******************************************************************************
    Dim fso
    Set fso = CreateObject("Scripting.FileSystemObject")

    ' Check precondition that file (or directory) exists; otherwise, the rest
    ' does not make sense. 
    If Not fso.FileExists( filename ) And Not fso.FolderExists( filename ) Then
	Call Err.Raise( ERROR_NOT_EXISTING, "writebackup", "The file " & Chr(34) & filename & Chr(34) & " does not exist." )
    End If

    Dim backupFilename
    If fso.FileExists( filename ) Then
	backupFilename = getBackupFilename( filename )
	If Not IsEmpty( backupFilename ) Then
	    Call fso.CopyFile( filename, backupFilename )
	End If
    Else
	Call archiver.archive( filename )
    End If
End Sub



'*******************************************************************************
'* PURPOSE:
'   main routine; call the writebackup() function on each passed filename.
'* ASSUMPTIONS / PRECONDITIONS:
'   ? List of any external variable, control, or other element whose state affects this procedure.
'* EFFECTS / POSTCONDITIONS:
'   ? List of the procedure's effect on each external variable, control, or other element.
'* INPUTS:
'   argc, argv
'* RETURN VALUES: 
'   none
'*******************************************************************************
Dim objArgs : Set objArgs = WScript.Arguments
If( objArgs.Count < 1 ) Then
    WScript.Echo( "writebackup: write backup of passed files with date file extension. " )
    WScript.Echo( "Syntax: " & WScript.ScriptName & " <filename> [,...]" )
    WScript.Quit 1
End If

Dim archiver : Set archiver = New ZipArchiver

' Process each passed filename
Dim i
For i = 0 to objArgs.Count - 1
    On Error Resume Next
    Call writebackup( objArgs( i ) )
    If Err Then
	Call MsgBox( Err.Description, vbCritical, WScript.ScriptName )
    End If
Next

