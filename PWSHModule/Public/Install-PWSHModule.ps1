
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

.PARAMETER ListName
The File Name on GitHub Gist.

.PARAMETER Scope
Where the module will be installed. AllUsers require admin access.

.PARAMETER AllowPrerelease
Allow the installation on beta modules.

.PARAMETER GitHubUserID
The GitHub User ID.

.PARAMETER PublicGist
Select if the list is hosted publicly.

.PARAMETER GitHubToken
GitHub Token with access to the Users' Gist.

.EXAMPLE
Install-PWSHModule -Filename extended -Scope CurrentUser -GitHubUserID smitpi -GitHubToken $GitHubToken

#>
Function Install-PWSHModule {
	[Cmdletbinding(DefaultParameterSetName = 'Private', HelpURI = 'https://smitpi.github.io/PWSHModule/Install-PWSHModule')]
	PARAM(
		[Parameter(Position = 0)]
		[string[]]$ListName,
		[Parameter(Position = 1)]
		[ValidateSet('AllUsers', 'CurrentUser')]
		[string]$Scope,
		[switch]$AllowPrerelease,
		[Parameter(Mandatory = $true)]
		[string]$GitHubUserID,
		[Parameter(ParameterSetName = 'Public')]
		[switch]$PublicGist,
		[Parameter(ParameterSetName = 'Private')]
		[string]$GitHubToken
	)

	if ($scope -like 'AllUsers') {
		Write-Verbose "[$(Get-Date -Format HH:mm:ss) BEGIN] Check for admin"
	 $IsAdmin = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
		if (-not($IsAdmin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) { Write-Error 'Must be running an elevated prompt.' }
	}

	try {
		if ($PublicGist) {
			Write-Host '[Using] ' -NoNewline -ForegroundColor Yellow 
			Write-Host 'Public Gist:' -NoNewline -ForegroundColor Cyan 
			Write-Host ' for list:' -ForegroundColor Green -NoNewline 
			Write-Host "$($ListName)" -ForegroundColor Cyan
		}

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

	foreach ($List in $ListName) {
		try {
			Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Checking Config File"
			$Content = (Invoke-WebRequest -Uri ($PRGist.files.$($List)).raw_url -Headers $headers).content | ConvertFrom-Json -ErrorAction Stop
		} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
		if ([string]::IsNullOrEmpty($Content.CreateDate) -or [string]::IsNullOrEmpty($Content.Modules)) {Write-Error 'Invalid Config File'}


		$InstallModuleSettings = @{
			AllowClobber       = $true
			Force              = $true
			SkipPublisherCheck = $true
		}
		if ($AllowPrerelease) {$InstallModuleSettings.add('AllowPrerelease', $true)}

		foreach ($module in $Content.Modules) {
			Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Checking for installed module"
			if ($module.Version -like 'Latest') {
				$mod = Get-Module -Name $module.Name
				if (-not($mod)) {$mod = Get-Module -Name $module.name -ListAvailable}
				if (-not($mod)) { 
					try {
						Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Installing module"
						Write-Host '[Installing] ' -NoNewline -ForegroundColor Yellow ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name)" -ForegroundColor Green -NoNewline ; Write-Host ' to scope: ' -ForegroundColor DarkRed -NoNewline ; Write-Host "$($scope)" -ForegroundColor Cyan
						Install-Module -Name $module.Name -Repository $module.Repository -Scope $Scope @InstallModuleSettings
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
								Install-Module -Name $module.name -Scope $Scope -Repository $module.Repository @InstallModuleSettings
							} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
						}
						Get-Module $module.name -ListAvailable | Remove-Module -Force -ErrorAction SilentlyContinue
						$mods = (Get-Module $module.name -ListAvailable | Sort-Object -Property version -Descending) | Select-Object -Skip 1
						foreach ($mod in $mods) {
							Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] UnInstalling module"
							Write-Host "`t[Uninstalling] " -NoNewline -ForegroundColor Yellow ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name)($($mod.Version)) " -ForegroundColor Green -NoNewline ; Write-Host "$($mod.Path)" -ForegroundColor DarkRed
							try {
								Uninstall-Module -Name $mod.name -RequiredVersion $mod.Version -Force
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
						Write-Host '[Installing] ' -NoNewline -ForegroundColor Yellow ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name)($($module.Version))" -ForegroundColor Green -NoNewline ; Write-Host ' to scope: ' -ForegroundColor DarkRed -NoNewline ; Write-Host "$($scope)" -ForegroundColor Cyan
						Install-Module -Name $module.Name -Repository $module.Repository -RequiredVersion $module.Version -Scope $Scope @InstallModuleSettings
					} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
				} else {
					Write-Host '[Installed] ' -NoNewline -ForegroundColor Green ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name) " -ForegroundColor Green -NoNewline ; Write-Host "$($mod.Path)" -ForegroundColor DarkRed
				}
			}
			Write-Verbose "[$(Get-Date -Format HH:mm:ss) DONE]"
		}
	}
} #end Function


$scriptblock = {
	param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
	if ([bool]($PSDefaultParameterValues.Keys -like "*PWSHModule*:GitHubUserID")) {(Show-PWSHModuleList).name}
}
Register-ArgumentCompleter -CommandName Install-PWSHModule -ParameterName ListName -ScriptBlock $scriptBlock
