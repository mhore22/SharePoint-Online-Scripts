Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
Add-Type -Path "C:\Program Files\SharePoint Online Management Shell\Microsoft.Online.SharePoint.PowerShell\Microsoft.SharePoint.Client.dll" 
Add-Type -Path "C:\Program Files\SharePoint Online Management Shell\Microsoft.Online.SharePoint.PowerShell\Microsoft.SharePoint.Client.Runtime.dll" 
Add-Type -Path "C:\Program Files\SharePoint Online Management Shell\Microsoft.Online.SharePoint.PowerShell\Microsoft.Online.SharePoint.Client.Tenant.dll"

function SyncListItems(){
	#Get Sharepoint List
	$spoUserName="#############"
	$spoUserPassword ="#############"
	$listName="#############"
	
	#Setup Credentials to connect
	$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($spoUserName,(ConvertTo-SecureString $spoUserPassword -AsPlainText -Force))
	
	#Set up the context
	$context = New-Object Microsoft.SharePoint.Client.ClientContext($webUrl) 
	$context.Credentials = $credentials
	
	#Get the List
	$List = $context.web.Lists.GetByTitle($listName)
	
	#sharepoint online get list items powershell
	$listItems = $List.GetItems([Microsoft.SharePoint.Client.CamlQuery]::CreateAllItemsQuery()) 
	$context.Load($listItems)
	$context.ExecuteQuery()

	#Database connection
	$instance = $databaseServer
	$userId = "#############"
	$password = "#############"
    $instance = "#############"
	$connectionstring = "Data Source=$instance;Initial Catalog=$instance; User Id=$userId; Password=$password;"

	#Loop through each item
	$ListItems | ForEach-Object {

		#Get the data on each item
		$id = $_["id"]
		$title = CatchNullValue($_["title"])
	
		#data to log
		$dataToLog = "Id = $id,
		Title = $title";

		#SQL command to execute
		$commandText = "UPDATE Table SET 
		id = @id,
		title = @title,
		WHERE id = @id"

		Try {
			# Migrate Data to SQL
			$sqlconnection = new-object system.data.sqlclient.sqlconnection
			$sqlconnection.connectionstring = $connectionstring
			$sqlconnection.open()
			$sqlcommand = new-object system.data.sqlclient.sqlcommand
			$sqlcommand.commandtimeout = 120
			$sqlcommand.connection = $sqlconnection
			$sqlcommand.commandtext = $commandText
			$sqlcommand.Parameters.Add("@id", $id) | Out-Null
			$sqlcommand.Parameters.Add("@title", $title) | Out-Null
	
			$rowsAffected = $sqlcommand.ExecuteNonQuery()

			$successMessage = "Data Sync is a SUCCESS with the following data $dataToLog"
			
			logInformation $successMessage
		}
		Catch {
			$errorMessage = "Data Sync FAILED with the following data $dataToLog with the following error  $_.Exception.StackTrace "
			logInformation $errorMessage
		}
	}  
}

function logInformation($message){
		#Get the current date
        $TimeStamp = (Get-Date).toString("yyyy-dd-MM-hh-mm-ss")
 
        #Get the Location of the script
        $CurrentDir = Split-Path -Parent $PSCommandPath
 
        #Log File with Current Directory and date
        $LogFile = $CurrentDir+ "\logs\data-sync-job-" + $TimeStamp + ".log"
 
        #Add Content to the Log File
        $Line = "$TimeStamp - $message"
        Add-content -Path $Logfile -Value $Line

}

#Check if the data is null then return a DBNull value
function CatchNullValue($data) {
   if ($data -ne $null) 
   { 
	 return $data
   }
   else { 
     return [DBNull]::Value
   }
}

#Web url and Database Server arguments
$webUrl = $args[0]
$databaseServer = $args[1]

#Start data Sync
SyncListItems