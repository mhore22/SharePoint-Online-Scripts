# Set the variables
$fileDirectory = Read-Host "Enter File Directory "

#Reading through the folder
function UploadPDFFiles(){
	foreach($file in Get-ChildItem -Path $fileDirectory -File -Recurse | Select-Object -ExpandProperty FullName)
	{	
		UploadFileToSPO $file
	}
}

function UploadFileToSPO($SourceFile){
	#Variables for Processing
	$SiteURL = ""
	$LibraryName =""
	
	#Setup Credentials to connect
	$userName=""
	$password =""
	$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($userName,(ConvertTo-SecureString $password -AsPlainText -Force))
   
	#Setup the context
	$Context = New-Object Microsoft.SharePoint.Client.ClientContext($SiteURL)
	$Context.Credentials = $credentials
	
	#Get the Library
	$Library =  $Context.Web.Lists.GetByTitle($LibraryName)
	
	#Get the file from disk
	$FileStream = ([System.IO.FileInfo] (Get-Item $SourceFile)).OpenRead()
	#Get File Name from source file path
	$SourceFileName = Split-path $SourceFile -leaf
	   
	#sharepoint online upload file powershell
	$FileCreationInfo = New-Object Microsoft.SharePoint.Client.FileCreationInformation
	$FileCreationInfo.Overwrite = $true
	$FileCreationInfo.ContentStream = $FileStream
	$FileCreationInfo.URL = $SourceFileName
	$FileUploaded = $Library.RootFolder.Files.Add($FileCreationInfo)
	  
	#Set metadata properties
    $ListItem = $FileUploaded.ListItemAllFields
    $ListItem["Title"] = $SourceFileName.replace(".pdf", "")
    $ListItem.Update()
	  
	#powershell upload single file to sharepoint online
	$Context.Load($FileUploaded) 
	$Context.ExecuteQuery() 
	 
	#Close file stream
	$FileStream.Close()
	
	Write-Host $SourceFileName " has been uploaded."
}

UploadPDFFiles