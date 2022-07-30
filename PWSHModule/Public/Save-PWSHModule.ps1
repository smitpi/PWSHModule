
<#PSScriptInfo

.VERSION 0.1.0

.GUID e28825fd-e9dd-4c96-beb9-950ba43f04ca

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
Created [13/07/2022_10:26] Initial Script Creating

.PRIVATEDATA

#>


<# 

.DESCRIPTION 
 Saves the module to a folder 

#> 


<#
.SYNOPSIS
Saves the modules from the specified list to a folder.

.DESCRIPTION
Saves the modules from the specified list to a folder.

.PARAMETER GitHubUserID
The GitHub User ID.

.PARAMETER PublicGist
Select if the list is hosted publicly.

.PARAMETER GitHubToken
GitHub Token with access to the Users' Gist.

.PARAMETER ListName
The File Name on GitHub Gist.

.PARAMETER AsNuGet
Save in the NuGet format

.PARAMETER Path
Where to save

.EXAMPLE
Save-PWSHModule -GitHubUserID smitpi -GitHubToken $GithubToken -ListName extended -AsNuGet -Path c:\temp\

#>
Function Save-PWSHModule {
	[Cmdletbinding(DefaultParameterSetName = 'Private', HelpURI = 'https://smitpi.github.io/PWSHModule/Save-PWSHModule')]
	PARAM(
		[Parameter(Mandatory = $true)]
		[string]$GitHubUserID, 
		[Parameter(ParameterSetName = 'Public')]
		[switch]$PublicGist,
		[Parameter(ParameterSetName = 'Private')]
		[string]$GitHubToken,
		[Parameter(Mandatory = $true)]
		[string]$ListName,
		[switch]$AsNuGet,
		[ValidateScript( { if (Test-Path $_) { $true }
				else { New-Item -Path $_ -ItemType Directory -Force | Out-Null; $true }
			})]
		[System.IO.DirectoryInfo]$Path = 'C:\Temp'
	)        
		
	try {
		Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Connect to Gist"
		$headers = @{}
		$auth = '{0}:{1}' -f $GitHubUserID, $GitHubToken
		$bytes = [System.Text.Encoding]::ASCII.GetBytes($auth)
		$base64 = [System.Convert]::ToBase64String($bytes)
		$headers.Authorization = 'Basic {0}' -f $base64

		$url = 'https://api.github.com/users/{0}/gists' -f $GitHubUserID
		$AllGist = Invoke-RestMethod -Uri $url -Method Get -Headers $headers -ErrorAction Stop
		$PRGist = $AllGist | Select-Object | Where-Object { $_.description -like 'PWSHModule-ConfigFile' }
	} catch {Write-Error "Can't connect to gist:`n $($_.Exception.Message)"}

	try {
		Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Checking Config File"
		$Content = (Invoke-WebRequest -Uri ($PRGist.files.$($ListName)).raw_url -Headers $headers).content | ConvertFrom-Json -ErrorAction Stop
	} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
	if ([string]::IsNullOrEmpty($Content.CreateDate) -or [string]::IsNullOrEmpty($Content.Modules)) {Write-Error 'Invalid Config File'}

	foreach ($module in $Content.Modules) {
		if ($module.Version -like 'Latest') {
			if ($AsNuGet) {
				try {
					Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Downloading"
					Write-Host '[Downloading] ' -NoNewline -ForegroundColor Yellow ; Write-Host 'NuGet: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name) " -ForegroundColor Green -NoNewline ; Write-Host "Path: $($Path)" -ForegroundColor DarkRed
					Save-Package -Name $module.Name -Provider NuGet -Source (Get-PSRepository -Name $module.Repository).SourceLocation -Path $Path | Out-Null
				} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
			} else {
				try {
					Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Downloading"
					Write-Host '[Downloading] ' -NoNewline -ForegroundColor Yellow ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name) " -ForegroundColor Green -NoNewline ; Write-Host "Path: $($Path)" -ForegroundColor DarkRed
					Save-Module -Name $module.name -Repository $module.Repository -Path $Path
				} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
			}
		} else {
			if ($AsNuGet) {
				try {
					Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Downloading"
					Write-Host '[Downloading] ' -NoNewline -ForegroundColor Yellow ; Write-Host 'NuGet: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name)(ver $($module.version)) " -ForegroundColor Green -NoNewline ; Write-Host "Path: $($Path)" -ForegroundColor DarkRed
					Save-Package -Name $module.Name -Provider NuGet -Source (Get-PSRepository -Name $module.Repository).SourceLocation -RequiredVersion $module.Version -Path $Path | Out-Null
				} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
			} else {
				try {
					Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Downloading"
					Write-Host '[Downloading] ' -NoNewline -ForegroundColor Yellow ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name)(ver $($module.version)) " -ForegroundColor Green -NoNewline ; Write-Host "Path: $($Path)" -ForegroundColor DarkRed
					Save-Module -Name $module.name -Repository $module.Repository -RequiredVersion $module.Version -Path $Path
				} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
			}

		}
	}
	Write-Verbose "[$(Get-Date -Format HH:mm:ss) DONE]"
} #end Function


$scriptblock = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
	if (($PSDefaultParameterValues.Keys	 -like "*GitHubUserID*")) {(Show-PWSHModuleList).name}
}
Register-ArgumentCompleter -CommandName Save-PWSHModule -ParameterName ListName -ScriptBlock $scriptBlock
