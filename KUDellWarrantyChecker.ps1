Clear-Host

<#
.SYNOPSIS
  Name: KUDellWarrantyChecker.ps1
  The purpose of this script is to ingest a CSV file containing Dell service tags, perform a Dell API lookup to grab their warranty data, then import that data into PDQ Inventory
  
.DESCRIPTION
  See synopsis

.NOTES
    Release Date: 2021-05-11T13:01
    Last Updated: 2021-05-11T14:04
   
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
    $encodedSecret = [System.Web.HttpUtility]::UrlEncode($clientSecret)

    $requestAccessTokenUri = "https://apigtwb2c.us.dell.com/auth/oauth/v2/token"
    $body = "grant_type=client_credentials&client_id=$clientID&client_id=$encodedSecret"
    $contentType = "application/x-www-form-urlencoded"
    try {
        $Token = Invoke-RestMethod -Method Post -Uri $requestAccessTokenUri -Body $body -ContentType $contentType
        $script:AuthenticationResult = Get-AuthToken -applicationId $ClientId -secret $ClientSecret
    }
    catch {
        throw
    }
}

# Function for retrieving Dell warranty data using token from Get-AuthToken
Function Retrieve-WarrantyData {
    Param (
        [string]$AuthToken,
        [array]$DellSvcTags
    )

    $warrantyCheckUri = "https://apigtwb2c.us.dell.com/PROD/sbil/eapi/v5/asset-entitlements"
    $headers = @{
        'Authorization' = $AuthToken
    }
    $body = $DellSvcTags

    try {
        $WarrantyEndDate = Invoke-RestMethod -Method GET -Uri $warrantyCheckUri -Headers $headers -Body $body
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

#TODO: Add code to generate Dell API bearer token using client_id and client_secret
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 # https://stackoverflow.com/questions/41618766/powershell-invoke-webrequest-fails-with-ssl-tls-secure-channel
Add-Type -AssemblyName System.Web #Required for the API lookups, not sure why. See https://www.undocumented-features.com/2020/06/30/powershell-oauth-authentication-two-ways/

#Get auth token. Lasts for 3600 seconds (1 hour).
$AuthenticationResult = Get-AuthToken -clientID $DellWarrantyProjectName -clientSecret $DellWarrantyAPIKey

#Create CSV file object
$InputCSVFile = Import-CSV $FullPathToInputCSV

#Iterate through CSV file
foreach ($line in $InputCSVFile) {
    Write-Host "ComputerName: $($line."Computer Name") DellServiceTag: $($line."Computer Serial Number")"
    #TODO: Write code to pull its warranty end date via Dell API for each service tag and dump it to an output CSV
    Retrieve-WarrantyData -AuthToken $AuthenticationResult -DellSvcTags $($line."Computer Serial Number")
    pause
}

#TODO: Write code to import data from output CSV into PDQ Inventory

#-------------------------- End main script body --------------------------

<# Info from email from Dell

As we use OAuth2.0 as the authorization hence it’s a two-step process to access warranty endpoint(s): 

1.                   Generate Bearer token using client_id and client_secret. The Bearer Token will be valid for 3600 seconds, you should generate token before it expires.

Kindly refrain to generate token for every call once you move to production instance 

HTTP POST Method ; URI : https://apigtwb2c.us.dell.com/auth/oauth/v2/token

requestBody

    grant_type = client_credentials

    client_id = your client_id

    client_secret = your client_secret

                          Content-Type = application/x-www-form-urlencoded
 

2.                   Use the Bearer token to make Warranty API call (new endpoints for warranty V5 API) wherein Bearer token should be passed as Header whilst servicetag(s) as query parameter - refer Warranty technical specs for more details

HTTP GET Method -  URI :   https://apigtwb2c.us.dell.com/PROD/sbil/eapi/v5/asset-entitlements

Headers

Authorization = Bearer token

Query Param (body) =
                                            servicetags = tag(s) e.g., tag1,tag2, tag3…

#>