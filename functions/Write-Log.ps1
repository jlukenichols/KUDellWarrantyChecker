function Write-Log {
#Function created by Luke Nichols
    Param ([string]$logString)

    if ($LoggingMode -eq $true) {
        #Generate fresh date info for logging dates/times into log
        $mostCurrentYear = (Get-Date).Year
        $mostCurrentMonth = ((Get-Date).Month).ToString("00")
        $mostCurrentDay = ((Get-Date).Day).ToString("00")
        $mostCurrentHour = ((Get-Date).Hour).ToString("00")
        $mostCurrentMinute = ((Get-Date).Minute).ToString("00")
        $mostCurrentSecond = ((Get-Date).Second).ToString("00")
  
        #Log the content
        $LogContent = "$mostCurrentYear-$mostCurrentMonth-$($mostCurrentDay)T$($mostCurrentHour):$($mostCurrentMinute):$($mostCurrentSecond),$logString"
        Add-Content $LogFilePath -value $LogContent
        if ($VerboseLogging -eq $true) {
            Write-Host $LogMessage
        }
    }
}

Function Delete-OldFiles {
#Function written by Luke Nichols
    param ([int]$NumberOfDays, [string]$PathToLogs)

    #Fetch the current date minus $NumberOfDays
    [DateTime]$limit = (Get-Date).AddDays(-$NumberOfDays)

    #Delete files older than $limit.
    Get-ChildItem -Path $PathToLogs | Where-Object { (($_.CreationTime -le $limit) -and (($_.Name -like "*.log*") -or ($_.Name -like "*.txt*"))) } | Remove-Item -Force
}