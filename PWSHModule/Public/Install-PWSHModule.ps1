
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

.PARAMETER LocalList
Select if the list is saved locally.

.PARAMETER Path
Directory where files are saved.

.PARAMETER Repository
Override the repository listed in the config file.

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
		[Parameter(Mandatory, ParameterSetName = 'Public')]
		[Parameter(Mandatory, ParameterSetName = 'Private')]
		[string]$GitHubUserID,
		[Parameter(ParameterSetName = 'Public')]
		[switch]$PublicGist,
		[Parameter(ParameterSetName = 'Private')]
		[string]$GitHubToken,
		[Parameter(ParameterSetName = 'local')]
		[switch]$LocalList,
		[Parameter(ParameterSetName = 'local')]
		[System.IO.DirectoryInfo]$Path,
		[string]$Repository
	)

	if ($scope -like 'AllUsers') {
		Write-Verbose "[$(Get-Date -Format HH:mm:ss) BEGIN] Check for admin"
	 $IsAdmin = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
		if (-not($IsAdmin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) { Write-Error 'Must be running an elevated prompt.' }
	}

	if ($GitHubUserID) {
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
	}
	[System.Collections.generic.List[PSObject]]$CombinedModules = @()
	foreach ($List in $ListName) {
		try {
			Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Checking Config File"
			if ($LocalList) {
				$ListPath = Join-Path $Path -ChildPath "$($list).json"
				if (Test-Path $ListPath) { 
					Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Collecting Content"
					$Content = Get-Content $ListPath | ConvertFrom-Json
    			} else {Write-Warning "List file $($List) does not exist"}
			} else {
				Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Collecting Content"
				$Content = (Invoke-WebRequest -Uri ($PRGist.files.$($List)).raw_url -Headers $headers).content | ConvertFrom-Json -ErrorAction Stop
			}
			if ([string]::IsNullOrEmpty($Content.CreateDate) -or [string]::IsNullOrEmpty($Content.Modules)) {Write-Error 'Invalid Config File'}
			Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Adding to list."
			$Content.Modules | Where-Object {$_ -notlike $null -and $_.name -notin $CombinedModules.name} | ForEach-Object {$CombinedModules.Add($_)}
		} catch {Write-Warning "Error: `n`tMessage:$($_.Exception)"}
	}

	foreach ($module in ($CombinedModules | Sort-Object -Property name -Unique)) {
		Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Checking for installed module"
		$InstallModuleSettings = @{
			AllowClobber       = $true
			Force              = $true
			SkipPublisherCheck = $true
			Repository         = $module.Repository
			Scope              = $Scope
		}
		if ($AllowPrerelease) {$InstallModuleSettings.add('AllowPrerelease', $true)}
		if ($Repository) {$InstallModuleSettings.Repository = $Repository}

		if ($module.Version -like 'Latest') {
			$mod = Get-Module -Name $module.Name
			if (-not($mod)) {$mod = Get-Module -Name $module.name -ListAvailable}
			if (-not($mod)) { 
				try {
					Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Installing module"
					Write-Host '[Installing] ' -NoNewline -ForegroundColor Yellow ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name)" -ForegroundColor Green -NoNewline ; Write-Host ' to scope: ' -ForegroundColor DarkRed -NoNewline ; Write-Host "$($scope)" -ForegroundColor Cyan
					Install-Module -Name $module.Name @InstallModuleSettings
				} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
			} else {
				try {
					Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Checking versions"
					Write-Host '[Installed] ' -NoNewline -ForegroundColor Green ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name) " -ForegroundColor Green -NoNewline ; Write-Host "$($mod.Path)" -ForegroundColor DarkRed
					$OnlineMod = Find-Module -Name $module.name -Repository $InstallModuleSettings.Repository
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
							Install-Module -Name $module.name @InstallModuleSettings
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
					Install-Module -Name $module.Name -RequiredVersion $module.Version @InstallModuleSettings
				} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
			} else {
				Write-Host '[Installed] ' -NoNewline -ForegroundColor Green ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name) " -ForegroundColor Green -NoNewline ; Write-Host "$($mod.Path)" -ForegroundColor DarkRed
			}
		}
		Write-Verbose "[$(Get-Date -Format HH:mm:ss) DONE]"
	}

} #end Function


$scriptblock = {
	param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
	if ([bool]($PSDefaultParameterValues.Keys -like '*:GitHubUserID')) {(Get-PWSHModuleList).name | Where-Object {$_ -like "*$wordToComplete*"}}
}
Register-ArgumentCompleter -CommandName Install-PWSHModule -ParameterName ListName -ScriptBlock $scriptBlock
