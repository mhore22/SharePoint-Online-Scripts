########## 

# This script gets all the site and subsites from a site collection then
# saves each Site Title and URL of the site into a CSV file.

##########

#Load SharePoint CSOM Assemblies
Add-Type -Path "C:\Program Files\SharePoint Online Management Shell\Microsoft.Online.SharePoint.PowerShell\Microsoft.SharePoint.Client.dll" 
Add-Type -Path "C:\Program Files\SharePoint Online Management Shell\Microsoft.Online.SharePoint.PowerShell\Microsoft.SharePoint.Client.Runtime.dll" 
Add-Type -Path "C:\Program Files\SharePoint Online Management Shell\Microsoft.Online.SharePoint.PowerShell\Microsoft.Online.SharePoint.Client.Tenant.dll"

# SharePoint Online Site Collection URL
$siteUrl = ""

# Credentials
$userName=""
$password =""

# Create Secure Password
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force

# Set up the context
$ctx = New-Object Microsoft.SharePoint.Client.ClientContext($siteUrl)
$ctx.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($username, $securePassword)

# Retrieve the site collection
$site = $ctx.Site
$ctx.Load($site)
$ctx.ExecuteQuery()

# Create an array list to store site information
$sitesInfo = New-Object System.Collections.ArrayList

# Function to retrieve subsites recursively
function Get-Subsites($web)
{
    $ctx.Load($web.Webs)
    $ctx.ExecuteQuery()

    foreach ($subWeb in $web.Webs)
    {
        $siteInfo = New-Object PSObject -Property @{
            "Title" = $subWeb.Title
            "URL" = $subWeb.Url
        }
        $sitesInfo.Add($siteInfo) | Out-Null
        Get-Subsites -web $subWeb
    }
}

# Call the function to retrieve subsites
Get-Subsites -web $ctx.Web

#Get the Location of the script
$CurrentDir = Split-Path -Parent $PSCommandPath
 
# Export the results to a CSV file
$sitesInfo | Export-Csv -Path $CurrentDir+ "\logs\data-sync-job-" + $TimeStamp + "SharePointSites.csv" -NoTypeInformation

# Dispose of the SharePoint context
$ctx.Dispose()
