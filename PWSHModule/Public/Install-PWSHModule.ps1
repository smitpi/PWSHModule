
<#PSScriptInfo

.VERSION 0.1.0

.GUID 697d3691-74be-460a-806d-a531b3ee565c

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
Created [12/07/2022_07:38] Initial Script Creating

.PRIVATEDATA

#>


<# 

.DESCRIPTION 
 Install modules from a config file 

#> 

<#
.SYNOPSIS
Install modules from the specified list.

.DESCRIPTION
Install modules from the specified list.

.PARAMETER GitHubUserID
The GitHub User ID.

.PARAMETER PublicGist
Select if the list is hosted publicly.

.PARAMETER GitHubToken
GitHub Token with access to the Users' Gist.

.PARAMETER ListName
The File Name on GitHub Gist.

.PARAMETER Scope
Where the module will be installed. AllUsers require admin access.

.EXAMPLE
Install-PWSHModule -GitHubUserID smitpi -GitHubToken $GitHubToken -Filename extended -Scope CurrentUser

#>
Function Install-PWSHModule {
	[Cmdletbinding(DefaultParameterSetName = 'Private', HelpURI = 'https://smitpi.github.io/PWSHModule/Install-PWSHModule')]
	PARAM(
		[Parameter(Mandatory = $true)]
		[string]$GitHubUserID, 
		[Parameter(ParameterSetName = 'Public')]
		[switch]$PublicGist,
		[Parameter(ParameterSetName = 'Private')]
		[string]$GitHubToken,
		[Parameter(Mandatory = $true)]
		[string]$ListName,
		[Parameter(Mandatory = $true)]
		[ValidateSet('AllUsers', 'CurrentUser')]
		[string]$Scope
	)

	if ($scope -like 'AllUsers') {
		Write-Verbose "[$(Get-Date -Format HH:mm:ss) BEGIN] Check for admin"
	 $IsAdmin = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
		if (-not($IsAdmin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) { Write-Error 'Must be running an elevated prompt.' }
	}

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
		Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Checking for installed module"
		if ($module.Version -like 'Latest') {
			$mod = Get-Module -Name $module.Name
			if (-not($mod)) {$mod = Get-Module -Name $module.name -ListAvailable}
			if (-not($mod)) { 
				try {
					Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Installing module"
					Write-Host '[Installing] ' -NoNewline -ForegroundColor Yellow ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name)" -ForegroundColor Green -NoNewline ; Write-Host ' to scope: ' -ForegroundColor DarkRed -NoNewline ; Write-Host "$($scope)" -ForegroundColor Cyan
					Install-Module -Name $module.Name -Repository $module.Repository -Scope $Scope -Force -AllowClobber
				} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
			} else {
				try {
					Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Checking versions"
					Write-Host '[Installed] ' -NoNewline -ForegroundColor Green ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name) " -ForegroundColor Green -NoNewline ; Write-Host "$($mod.Path)" -ForegroundColor DarkRed
					$OnlineMod = Find-Module -Name $module.name -Repository $module.Repository
					[version]$Onlineversion = $OnlineMod.version 
					[version]$Localversion = ($mod | Sort-Object -Property Version -Descending)[0].Version
				} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
				if ($Localversion -lt $Onlineversion) {
					Write-Host "`t[Upgrading] " -NoNewline -ForegroundColor Yellow ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name)" -ForegroundColor Green -NoNewline; Write-Host " v$($OnlineMod.version)" -ForegroundColor DarkRed
					try {
						Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Updating module"
						Update-Module -Name $module.Name -Force -ErrorAction Stop
					} catch {
						try {
							Install-Module -Name $module.name -Scope $Scope -Repository $module.Repository -AllowClobber -Force
						} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
					}
				}
			}
		} else {
			Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Checking installed module"
			$mod = Get-Module -Name $module.Name
			if (-not($mod)) {$mod = Get-Module -Name $module.name -ListAvailable}
			if ((-not($mod)) -or $mod.Version -lt $module.Version) {
				try {
					Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Installing module"
					Write-Host '[Installing] ' -NoNewline -ForegroundColor Yellow ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name)($($module.Version))" -ForegroundColor Green  -NoNewline ; Write-Host ' to scope: ' -ForegroundColor DarkRed -NoNewline ; Write-Host "$($scope)" -ForegroundColor Cyan
					Install-Module -Name $module.Name -Repository $module.Repository -RequiredVersion $module.Version -Scope $Scope -Force -AllowClobber
				} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
			} else {
				Write-Host '[Installed] ' -NoNewline -ForegroundColor Green ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name) " -ForegroundColor Green -NoNewline ; Write-Host "$($mod.Path)" -ForegroundColor DarkRed
			}
		}
		Write-Verbose "[$(Get-Date -Format HH:mm:ss) DONE]"
	}
} #end Function
