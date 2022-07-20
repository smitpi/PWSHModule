
<#PSScriptInfo

.VERSION 0.1.0

.GUID 6eb98557-cfc1-49c2-ae2c-0cb7146d4ddd

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
Created [20/07/2022_19:06] Initial Script Creating

.PRIVATEDATA

#>

<# 

.DESCRIPTION 
 Will remove all versions of the module 

#> 


<#
.SYNOPSIS
Will uninstall the module from the system.

.DESCRIPTION
Will uninstall the module from the system. Select OldVersions to remove duplicates only.

.PARAMETER GitHubUserID
The GitHub User ID.

.PARAMETER PublicGist
Select if the list is hosted publicly.

.PARAMETER GitHubToken
GitHub Token with access to the Users' Gist.

.PARAMETER ListName
The File Name on GitHub Gist.

.PARAMETER OldVersions
Will only uninstall old versions of the module.

.PARAMETER ForceDeleteFolder
Will force delete the base folder.

.EXAMPLE
Uninstall-PWSHModule -GitHubUserID smitpi -PublicGist -ListName base -OldVersions

#>
Function Uninstall-PWSHModule {
	[Cmdletbinding(DefaultParameterSetName = 'Private', HelpURI = 'https://smitpi.github.io/PWSHModule/Install-PWSHModule')]
	PARAM(
		[Parameter(Mandatory = $true)]
		[string]$GitHubUserID, 
		[Parameter(ParameterSetName = 'Public')]
		[switch]$PublicGist,
		[Parameter(ParameterSetName = 'Private')]
		[string]$GitHubToken,
		[Parameter(Mandatory = $true)]
		[ValidateScript( { $IsAdmin = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
				if ($IsAdmin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { $True }
				else { Throw 'Must be running an elevated prompt.' } })]
		[string]$ListName,
		[switch]$OldVersions,
		[switch]$ForceDeleteFolder
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
		Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Checking for installed module"
		if ($OldVersions) {
			Get-Module $module.name -ListAvailable | Remove-Module -Force -ErrorAction SilentlyContinue
			$mods = (Get-Module $module.name -ListAvailable | Sort-Object -Property version -Descending) | Select-Object -Skip 1
			foreach ($mod in $mods) {
				Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] UnInstalling module"
				Write-Host '[Uninstalling] ' -NoNewline -ForegroundColor Yellow ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name)($($mod.Version)) " -ForegroundColor Green -NoNewline ; Write-Host "$($mod.Path)" -ForegroundColor DarkRed
				try {
					Uninstall-Module -Name $mod.name -RequiredVersion $mod.Version -Force
				} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
			}
		} elseif ($OldVersions -and $ForceDeleteFolder) {
			Get-Module $module.name -ListAvailable | Remove-Module -Force -ErrorAction SilentlyContinue
			$mods = (Get-Module $module.name -ListAvailable | Sort-Object -Property version -Descending) | Select-Object -Skip 1
			foreach ($mod in $mods) {
				Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Deleting Folder"
				Write-Host '[Deleting] ' -NoNewline -ForegroundColor Yellow ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name)($($mod.Version)) " -ForegroundColor Green -NoNewline ; Write-Host "$($mod.Path)" -ForegroundColor DarkRed
				try {
					$folder = Get-Module -Name $mod.name -ListAvailable | Where-Object {$_.version -like $mod.version}
					Get-ChildItem -Path (Get-Item $folder.Path).Directory -Recurse | Remove-Item -Force -Recurse
				} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
			}
		} else {
			try {
				Write-Host '[Uninstalling]' -NoNewline -ForegroundColor Yellow ; Write-Host 'All Versions of Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name) " -ForegroundColor Green
				Uninstall-Module -Name $module.Name -AllVersions -Force
			} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
		}
		Write-Verbose "[$(Get-Date -Format HH:mm:ss) DONE]"
	}
} #end Function
