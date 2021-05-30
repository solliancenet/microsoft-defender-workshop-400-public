function CreateApplication()
{
    #TODO
}

function GetAccessToken()
{
    #Get current working directory
    $scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

    #Paste below your Tenant ID, App ID and App Secret (App key).
    $tenantId = '' ### Paste your tenant ID here
    $appId = '' ### Paste your Application ID here
    $appSecret = '' ### Paste your Application secret here

    $resourceAppIdUri = 'https://graph.windows.net'
    $oAuthUri = "https://login.microsoftonline.com/$tenantId/oauth2/token"
    $authBody = [Ordered] @{
        resource = "$resourceAppIdUri"
        client_id = "$appId"
        client_secret = "$appSecret"
        grant_type = 'client_credentials'
    }

    #call API
    $authResponse = Invoke-RestMethod -Method Post -Uri $oAuthUri -Body $authBody -ErrorAction Stop
    $authResponse
    Out-File -FilePath "$scriptDir\LatestSIEM-token.txt" -InputObject $authResponse.access_token
}

function GetAlerts()
{
    #Get current working directory
    $scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

    #run the script Get-Token.ps1  - make sure you are running this script from the same folder of Get-SIEMToken.ps1
    $token = Get-Content "$scriptDir\LatestSIEM-token.txt"

    #Get Alert from the last xx hours 200 in this example. Make sure you have alerts in that time frame.
    $dateTime = (Get-Date).ToUniversalTime().AddHours(-200).ToString("o")

    #test SIEM API
    $url = 'https://wdatp-alertexporter-us.windows.com/api/alerts?limit=20&sinceTimeUtc=2020-01-01T00:00:00.000'

    #Set the WebRequest headers
    $headers = @{ 
        'Content-Type' = 'application/json'
        Accept = 'application/json'
        Authorization = "Bearer $token" 
    }

    #Send the webrequest and get the results. 
    $response = Invoke-WebRequest -Method Get -Uri $url -Headers $headers -ErrorAction Stop
    $response
    Write-Host

    #Extract the alerts from the results.  This works for SIEM API:
    $alerts =  $response.Content | ConvertFrom-Json | ConvertTo-Json

    #Get string with the execution time. We concatenate that string to the output file to avoid overwrite the file
    $dateTimeForFileName = Get-Date -Format o | foreach {$_ -replace ":", "."}    

    #Save the result as json and as csv
    $outputJsonPath = "$scriptDir\Latest Alerts $dateTimeForFileName.json"     
    $outputCsvPath = "$scriptDir\Latest Alerts $dateTimeForFileName.csv"

    Out-File -FilePath $outputJsonPath -InputObject $alerts
    Get-Content -Path $outputJsonPath -Raw | ConvertFrom-Json | Select-Object -ExpandProperty value | Export-CSV $outputCsvPath -NoTypeInformation
}

#CreateApplication;

$token = GetAccessToken;

GetAlerts;