
<#PSScriptInfo

.VERSION 0.1.0

.GUID f2314cf6-8ba1-49f0-b09d-396d72749014

.AUTHOR Pierre Smit

.COMPANYNAME HTPCZA Tech

.COPYRIGHT

.TAGS ps

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
Created [09/07/2022_15:22] Initial Script Creating

.PRIVATEDATA

#>

<# 

.DESCRIPTION 
 Create a new config file. 

#> 


<#
.SYNOPSIS
Add a new list to GitHub Gist.

.DESCRIPTION
Add a new list to GitHub Gist.

.PARAMETER GitHubUserID
The GitHub User ID.

.PARAMETER GitHubToken
GitHub Token with access to the Users' Gist.

.PARAMETER ListName
The File Name on GitHub Gist.

.PARAMETER Description
Summary of the function for the list.

.EXAMPLE
New-PWSHModuleList -GitHubUserID smitpi -GitHubToken $GitHubToken -ListName Base -Description "These modules needs to be installed on all servers"

#>
Function New-PWSHModuleList {
	[Cmdletbinding( HelpURI = 'https://smitpi.github.io/PWSHModule/New-PWSHModuleList')]
	PARAM(
		[Parameter(Mandatory = $true)]
		[string]$GitHubUserID, 
		[Parameter(Mandatory = $true)]
		[string]$GitHubToken,
		[Parameter(Mandatory = $true)]
		[string]$ListName,
		[Parameter(Mandatory = $true)]
		[string]$Description
	)

	Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Creating config"
	$NewConfig = [PSCustomObject]@{
		CreateDate   = (Get-Date -Format u)
		Description  = $Description
		Author       = "$($env:USERNAME.ToLower())@$($env:USERDNSDOMAIN.ToLower())"
		ModifiedDate = 'Unknown'
		ModifiedUser = 'Unknown'
		Modules      = [PSCustomObject]@{
			Name        = 'PWSHModule'
			Version     = 'Latest'
			Description = 'Uses a GitHub Gist File to install and maintain a list of PowerShell Modules'
			Repository  = 'PSGallery'
			Projecturi  = 'https://github.com/smitpi/PWSHModule'
		}
 } | ConvertTo-Json

	$ConfigFile = Join-Path $env:TEMP -ChildPath "$($ListName).json"
	Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Create temp file"
	if (Test-Path $ConfigFile) {
		Write-Warning "Config File exists, Renaming file to $($ListName)-$(Get-Date -Format yyyyMMdd_HHmm).json"	
		try {
			Rename-Item $ConfigFile -NewName "$($ListName)-$(Get-Date -Format yyyyMMdd_HHmm).json" -Force -ErrorAction Stop | Out-Null
		} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message);exit"}
	}
	try {
		$NewConfig | Set-Content -Path $ConfigFile -Encoding utf8 -ErrorAction Stop
	} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}


	try {
		Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Connecting to Gist"
		$headers = @{}
		$auth = '{0}:{1}' -f $GitHubUserID, $GitHubToken
		$bytes = [System.Text.Encoding]::ASCII.GetBytes($auth)
		$base64 = [System.Convert]::ToBase64String($bytes)
		$headers.Authorization = 'Basic {0}' -f $base64

		$url = 'https://api.github.com/users/{0}/gists' -f $GitHubUserID
		$AllGist = Invoke-RestMethod -Uri $url -Method Get -Headers $headers -ErrorAction Stop
		$PRGist = $AllGist | Select-Object | Where-Object { $_.description -like 'PWSHModule-ConfigFile' }
	} catch {Write-Error "Can't connect to gist:`n $($_.Exception.Message)"}

		
	if ([string]::IsNullOrEmpty($PRGist)) {
		try {
			Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Uploading to gist"
			$Body = @{}
			$files = @{}
			$Files["$($ListName)"] = @{content = ( Get-Content (Get-Item $ConfigFile).FullName -Encoding UTF8 | Out-String ) }
			$Body.files = $Files
			$Body.description = 'PWSHModule-ConfigFile'
			$json = ConvertTo-Json -InputObject $Body
			$json = [System.Text.Encoding]::UTF8.GetBytes($json)
			$null = Invoke-WebRequest -Headers $headers -Uri https://api.github.com/gists -Method Post -Body $json -ErrorAction Stop
			Write-Host '[Uploaded]' -NoNewline -ForegroundColor Yellow; Write-Host " $($ListName).json" -NoNewline -ForegroundColor Cyan; Write-Host ' to Github Gist' -ForegroundColor Green

		} catch {Write-Error "Can't connect to gist:`n $($_.Exception.Message)"}
	} else {
		try {
			Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Uploading to Gist"
			$Body = @{}
			$files = @{}
			$Files["$($ListName)"] = @{content = ( Get-Content (Get-Item $ConfigFile).FullName -Encoding UTF8 | Out-String ) }
			$Body.files = $Files
			$Uri = 'https://api.github.com/gists/{0}' -f $PRGist.id
			$json = ConvertTo-Json -InputObject $Body
			$json = [System.Text.Encoding]::UTF8.GetBytes($json)
			$null = Invoke-WebRequest -Headers $headers -Uri $Uri -Method Patch -Body $json -ErrorAction Stop
			Write-Host '[Uploaded]' -NoNewline -ForegroundColor Yellow; Write-Host " $($ListName).json" -NoNewline -ForegroundColor Cyan; Write-Host ' to Github Gist' -ForegroundColor Green
		} catch {Write-Error "Can't connect to gist:`n $($_.Exception.Message)"}
	}
	Write-Verbose "[$(Get-Date -Format HH:mm:ss) DONE]"


} #end Function
