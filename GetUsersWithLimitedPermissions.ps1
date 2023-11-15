# This script is use to get users that don't have any permissions

Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
Add-Type -Path "C:\Program Files\SharePoint Online Management Shell\Microsoft.Online.SharePoint.PowerShell\Microsoft.SharePoint.Client.dll" 
Add-Type -Path "C:\Program Files\SharePoint Online Management Shell\Microsoft.Online.SharePoint.PowerShell\Microsoft.SharePoint.Client.Runtime.dll" 
Add-Type -Path "C:\Program Files\SharePoint Online Management Shell\Microsoft.Online.SharePoint.PowerShell\Microsoft.Online.SharePoint.Client.Tenant.dll"
Add-Type -Path "C:\Program Files\SharePoint Online Management Shell\Microsoft.Online.SharePoint.PowerShell\Microsoft.SharePoint.Client.Publishing.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.Taxonomy.dll" 

$ReportFile="C:\Temp\UsersWithNoPermissions.csv"

function GetUsersWithLimitedAccess(){
param(
    $SiteURL = $(throw "Please Enter the Site Collection URL")
)
 
	Try {
		"User `t APIUrl" | out-file $ReportFile
		
		#Setup Credentials to connect
		$userName="" # The Username
		$password ="" # The Password
		$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($userName,(ConvertTo-SecureString $password -AsPlainText -Force))
	   
		#Setup the context
		$Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($SiteURL)
		$Ctx.Credentials = $credentials
		
		$web = $Ctx.Web

		#Get all users of the site collection
		$users = $Ctx.Web.SiteUsers
		$Ctx.Load($users) 
		$Ctx.ExecuteQuery()
		
		Foreach($user in $users)
		{
			$userId = $user.Id
			$RequestURL = $SiteURL + "/_api/web/GetUserById("+ $user.Id +")/Groups"
			$AuthenticationCookie = $credentials.GetAuthenticationCookie($SiteURL, $true)
			$WebSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession
			$WebSession.Credentials = $Ctx.Credentials
			$WebSession.Cookies.SetCookies($SiteUrl, $AuthenticationCookie)
			$WebSession.Headers.Add("Accept", "application/json;odata=verbose")
			
			#Invoke Rest Method
			$Result = Invoke-RestMethod -Method Get -WebSession $WebSession -Uri $RequestURL
			
			Write-Host "Getting groups for " $user.Title
			
			if($Result.d.results.Length -eq 0){
				Write-host -f Cyan "$user.Title don't have any permission."
				"$user.Title`t $($RequestURL)" | Out-File $ReportFile -Append
			}
		}

	}
	Catch {
		write-host -f Red "Error:" $_.Exception.Message
	}
}

#The Site URL to check
$SiteURL = ""

#Call the function
GetUsersWithLimitedAccess -SiteURL $SiteUrl