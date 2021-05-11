Clear-Host
#This is required because you will get a TLS error otherwise. I think Invoke-RestMethod uses TLS 1.0 by default or something.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 # https://stackoverflow.com/questions/41618766/powershell-invoke-webrequest-fails-with-ssl-tls-secure-channel
#Required for the API lookups, not sure why.
Add-Type -AssemblyName System.Web # https://www.undocumented-features.com/2020/06/30/powershell-oauth-authentication-two-ways/

<#
.SYNOPSIS
  Name: KUDellWarrantyChecker.ps1
  The purpose of this script is to ingest a CSV file containing Dell service tags, perform a Dell API lookup to grab their warranty data, then import that data into PDQ Inventory
  
.DESCRIPTION
  See synopsis

.NOTES
    Release Date: 2021-05-11T13:01
    Last Updated: 2021-05-11T18:14
   
    Author: Luke Nichols
    Github link: https://github.com/jlukenichols/KUDellWarrantyChecker

.EXAMPLE
    Just run the script without parameters, it's not designed to be called like a function
#>

#-------------------------- Begin defining functions --------------------------

# Dot-source functions for writing to log files
. .\functions\Write-Log.ps1

# Function for generating Dell API auth token
Function Get-AuthToken {
    #Mostly taken from https://www.undocumented-features.com/2020/06/30/powershell-oauth-authentication-two-ways/ but adapted to the Dell API
    Param (
        [string]$clientID,
        [string]$clientSecret
    )

    $requestAccessTokenUri = "https://apigtwb2c.us.dell.com/auth/oauth/v2/token" # Production Endpoint    
    $body = "client_id=$($clientID)&client_secret=$($clientSecret)&grant_type=client_credentials"
    $contentType = "application/x-www-form-urlencoded"
    try {
        #Retrieve token
        $Auth = Invoke-WebRequest "$($requestAccessTokenUri)?client_id=$($clientID)&client_secret=$($clientSecret)&grant_type=client_credentials" -Method Post #https://www.powershellgallery.com/packages/Get-DellWarranty/2.0.0.0

        #Convert result from JSON to PS object
        $Auth = ($Auth | ConvertFrom-Json)

        $script:AuthenticationResult = $Auth.access_token
        $script:TokenExpiration = (get-date).AddSeconds($Auth.expires_in)
    }
    catch {
        throw
    }
}

# Function for retrieving Dell warranty data using token from Get-AuthToken
Function Retrieve-WarrantyData {
    Param (
        [string]$AuthToken,
        [string]$DellSvcTag
    )

    $warrantyCheckUri = "https://apigtwb2c.us.dell.com/PROD/sbil/eapi/v5/asset-entitlements"
    $headers = @{
        'Authorization' = "Bearer $AuthToken"
    }
    $parameters = @{
        'servicetags' = $DellSvcTag
    }
    
    try {
        $APIResults = Invoke-RestMethod -Uri $warrantyCheckUri -Headers $headers -Body $parameters -Method GET
        $APIResults = ($APIResults | ConvertTo-Json | ConvertFrom-Json)
        return $APIResults
    } catch {
        throw
    }
}

#-------------------------- End defining functions --------------------------

#-------------------------- Set any initial values --------------------------
$ScriptExecutionDate = Get-Date

#Grab the individual portions of the date and put them in vars
[DateTime]$currentDate=Get-Date
$currentYear = $($currentDate.Year)
$currentMonth = $($currentDate.Month).ToString("00")
$currentDay = $($currentDate.Day).ToString("00")

$currentHour = $($currentDate.Hour).ToString("00")
$currentMinute = $($currentDate.Minute).ToString("00")
$currentSecond = $($currentDate.Second).ToString("00")

#Dot-source settings file
if (Test-Path .\CustomSettings.ps1) {
    . .\CustomSettings.ps1
    $LogMessage = "Importing settings from CustomSettings.ps1"
} else {
    . .\DefaultSettings.ps1
    $LogMessage = "Importing settings from DefaultSettings.ps1"
}

#-------------------------- End setting initial values --------------------------

#-------------------------- Start main script body --------------------------

# Self-elevate the script if required
# https://blog.expta.com/2017/03/how-to-self-elevate-powershell-script.html
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
 if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
  $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
  Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
  Exit
 }
}

#Clean out old log files
Delete-OldFiles -NumberOfDays 30 -PathToLogs "$($myPSScriptRoot)\logs"

#Start the log file
Write-Log $LogMessage

#Show the path to the input file in the log
$LogMessage = "`$FullPathToCSV = $FullPathToCSV"
Write-Log $LogMessage

#Get auth token. Lasts for 3600 seconds.
if ($TokenExpiration -lt (Get-Date)) {
    #Token is expired. Get a new one.
    Write-Host "Generating new auth token..."
    Get-AuthToken -clientID $DellWarrantyAPIKey -clientSecret $DellWarrantyAPIKeySecret #token is written to $AuthenticationResult within the function
} else {
    #Token is still valid. Keep using it.
    Write-Host "Found previously generated auth token that is still valid."
}

#TODO: Wrap this into a function

#Create new file, overwriting old one
$LogMessage = "Creating new output file at $FullPathToOutputCSV"
Write-Log $LogMessage
$OutputCSVHeaderLine | Out-File $FullPathToOutputCSV

#Create CSV file object for input file
$InputCSVFile = Import-CSV $FullPathToInputCSV

#Iterate through CSV file
$LogMessage = "Looping through input file..."
Write-Log $LogMessage
foreach ($line in $InputCSVFile) {
    Write-Host "`nComputerName: $($line."Computer Name")"
    Write-Host "DellServiceTag: $($line."Computer Serial Number")"
    $WarrantyData = Retrieve-WarrantyData -AuthToken $AuthenticationResult -DellSvcTag $($line."Computer Serial Number")
    $ShipDate = $($WarrantyData.ShipDate)

    #Because one device can have various warranties, just grab the biggest (maximum) date
    $EntitlementEndDate = ($($WarrantyData.entitlements.endDate) | measure -maximum).maximum

    #Build new line for output CSV file
    $CSVLine = "$($line."Computer Name"),$($ShipDate),$($EntitlementEndDate)"

    #Append new line to output CSV file
    $CSVLine | Out-File $FullPathToOutputCSV -Append
}

#TODO: Write code to detect if the custom fields exist already and create them if they don't

#Import data into PDQ Inventory
$LogMessage = "Importing data into PDQ Inventory..."
Write-Log $LogMessage
#https://www.pdq.com/blog/adding-custom-fields-multiple-computers-powershell/
& $PDQInvExecPath ImportCustomFields -FileName "$FullPathToOutputCSV" -ComputerColumn "Computer Name" -CustomFields "$ShipDateCustomFieldName=$ShipDateCustomFieldName,$EntitlementEndDateCustomFieldName=$EntitlementEndDateCustomFieldName"
#TODO: Wrap this into a function

$LogMessage = "Closing log file."
Write-Log $LogMessage

#-------------------------- End main script body --------------------------