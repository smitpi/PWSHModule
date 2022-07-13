
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

#Requires -Module PSWriteColor

<# 

.DESCRIPTION 
 Create a new config file. 

#> 


<#
.SYNOPSIS
Create a new config file.

.DESCRIPTION
Create a new config file.

.PARAMETER Export
Export the result to a report file. (Excel or html). Or select Host to display the object on screen.

.PARAMETER ReportPath
Where to save the report.

.EXAMPLE
New-PWSHModuleConfigFile -Export HTML -ReportPath C:\temp

#>
<#
.SYNOPSIS
Create a new config file.

.DESCRIPTION
Create a new json config file in the path specified.

.PARAMETER Path
Path where the config file will be created. If the path doesn't exist, it will be created.

.EXAMPLE
New-PWSHModuleConfigFile -Path C:\temp

#>
Function New-PWSHModuleConfigFile {
	[Cmdletbinding( HelpURI = 'https://smitpi.github.io/PWSHModule/New-PWSHModuleConfigFile')]
	[OutputType([System.Object[]])]
	PARAM(
		[string]$GitHubUserID, 
		[string]$GitHubToken,
		[string]$ListName,
		[string]$Description
	)

	$NewConfig = [PSCustomObject]@{
		CreateDate   = (Get-Date -Format u)
		Description  = $Description
		Author       = "$($env:USERNAME.ToLower())@$($env:USERDNSDOMAIN.ToLower())"
		Modified     = 'Unknown'
		Modules      = [PSCustomObject]@{
			Name        = 'PWSHModule'
			Version     = 'Latest'
			Description = 'Uses a Config file to install and maintain a list of PowerShell Modules'
			Repository  = 'PSGallery'
			Projecturi  = 'https://github.com/smitpi/PWSHModule'
		}
 } | ConvertTo-Json

	$ConfigFile = Join-Path $env:TEMP -ChildPath "$($ListName).json"
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
		$headers = @{}
		$auth = '{0}:{1}' -f $GitHubUserID, $GitHubToken
		$bytes = [System.Text.Encoding]::ASCII.GetBytes($auth)
		$base64 = [System.Convert]::ToBase64String($bytes)
		$headers.Authorization = 'Basic {0}' -f $base64

		$url = 'https://api.github.com/users/{0}/gists' -f $GitHubUserID
		$AllGist = Invoke-RestMethod -Uri $url -Method Get -Headers $headers -ErrorAction Stop
		$PRGist = $AllGist | Select-Object | Where-Object { $_.description -like 'PWSHModule-ConfigFile' }
	} catch {throw "Can't connect to gist:`n $($_.Exception.Message)"}

		
	if ([string]::IsNullOrEmpty($PRGist)) {
		try {
			$Body = @{}
			$files = @{}
			$Files["$($ListName)"] = @{content = ( Get-Content (Get-Item $ConfigFile).FullName -Encoding UTF8 | Out-String ) }
			$Body.files = $Files
			$Body.description = 'PWSHModule-ConfigFile'
			$json = ConvertTo-Json -InputObject $Body
			$json = [System.Text.Encoding]::UTF8.GetBytes($json)
			$null = Invoke-WebRequest -Headers $headers -Uri https://api.github.com/gists -Method Post -Body $json -ErrorAction Stop
			Write-Host '[Uploaded]' -NoNewline -ForegroundColor Yellow; Write-Host " $($ListName).json" -NoNewline -ForegroundColor Cyan; Write-Host ' to Github Gist' -ForegroundColor Green

		} catch {throw "Can't connect to gist:`n $($_.Exception.Message)"}
	} else {
		try {
			$Body = @{}
			$files = @{}
			$Files["$($ListName)"] = @{content = ( Get-Content (Get-Item $ConfigFile).FullName -Encoding UTF8 | Out-String ) }
			$Body.files = $Files
			$Uri = 'https://api.github.com/gists/{0}' -f $PRGist.id
			$json = ConvertTo-Json -InputObject $Body
			$json = [System.Text.Encoding]::UTF8.GetBytes($json)
			$null = Invoke-WebRequest -Headers $headers -Uri $Uri -Method Patch -Body $json -ErrorAction Stop
			Write-Host '[Uploaded]' -NoNewline -ForegroundColor Yellow; Write-Host " $($ListName).json" -NoNewline -ForegroundColor Cyan; Write-Host ' to Github Gist' -ForegroundColor Green
		} catch {throw "Can't connect to gist:`n $($_.Exception.Message)"}
	}
} #end Function
