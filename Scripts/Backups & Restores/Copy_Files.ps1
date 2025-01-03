$sourceDBName=""
$site="EU"
$targetservername=""


# Source and destination directories
$sourceDirList = "C:\Temp\PSScript_CopyFiles\$($site)_TlogDir_$sourceDBName.txt"
$destinationDir = "\\$targetservername\TempBackups\$sourceDBName"

$destinationDir

# Read the list of directories from the file
$sourceDirectories = Get-Content $sourceDirList

    foreach ($sourceDir in $sourceDirectories) {
        $sourceDir
        $result.SourceBackupFinishDate
        # Filter .txt files created within the past 5 days
        $filesToCopy = Get-ChildItem -Path $sourceDir -Filter *.trn | Where-Object {$_.LastWriteTime -ge $result.SourceBackupFinishDate} |Sort LastWriteTime 
        # Copy filtered files to the destination directory
        foreach ($file in $filesToCopy) {
            $destinationFile = Join-Path -Path $destinationDir -ChildPath $file.Name
            $sourceFile = Join-Path -Path $sourceDir -ChildPath $file.Name
            if (-not (Test-Path -Path $destinationFile)) {
            # Copy the file if it doesn't exist at the destination
            Copy-Item -Path $sourceFile -Destination $destinationFile
        } else {
            Write-Host "File already exists at the destination. Skipping."
        }
    }
}