
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

.PARAMETER ListName
The File Name on GitHub Gist.

.PARAMETER AsNuGet
Save in the NuGet format

.PARAMETER AddPathToPSModulePath
Add path to environmental variable PSModulePath.

.PARAMETER Path
Where to save.

.PARAMETER Repository
Override the repository listed in the config file.

.PARAMETER GitHubUserID
The GitHub User ID.

.PARAMETER PublicGist
Select if the list is hosted publicly.

.PARAMETER GitHubToken
GitHub Token with access to the Users' Gist.

.PARAMETER LocalList
Select if the list is saved locally.

.PARAMETER ListPath
Directory where list files are saved.

.EXAMPLE
Save-PWSHModule -ListName extended -AsNuGet -Path c:\temp\ -GitHubUserID smitpi -GitHubToken $GitHubToken

#>
Function Save-PWSHModule {
	[Cmdletbinding(DefaultParameterSetName = 'Private', HelpURI = 'https://smitpi.github.io/PWSHModule/Save-PWSHModule')]
	PARAM(
		[Parameter(Mandatory, Position = 0)]
		[string[]]$ListName,
		
		[Parameter(Mandatory, ParameterSetName = 'nuget')]
		[Parameter(ParameterSetName = 'public')]
		[Parameter(ParameterSetName = 'private')]
		[Parameter(ParameterSetName = 'local')]
		[switch]$AsNuGet,
			
		[ValidateScript( { if (Test-Path $_) { $true }
				else { New-Item -Path $_ -ItemType Directory -Force | Out-Null; $true }
			})]
		[Parameter(Mandatory)]
		[System.IO.DirectoryInfo]$Path,

		[ValidateScript( { $IsAdmin = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
				if ($IsAdmin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { $True }
				else { Throw 'Must be running an elevated prompt.' } })]
		[switch]$AddPathToPSModulePath,

		[string]$Repository,
		
		[Parameter(mandatory, ParameterSetName = 'public')]
		[Parameter(mandatory, ParameterSetName = 'private')]
		[string]$GitHubUserID, 
		
		[Parameter(mandatory, ParameterSetName = 'public')]
		[switch]$PublicGist,
		
		[Parameter(mandatory, ParameterSetName = 'private')]
		[string]$GitHubToken,
		
		[Parameter(mandatory, ParameterSetName = 'local')]
		[switch]$LocalList,
		
		[Parameter(mandatory, ParameterSetName = 'local')]
		[System.IO.DirectoryInfo]$ListPath
	)

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
				$ListPath = Join-Path $ListPath -ChildPath "$($list).json"
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
		if ($Repository) {$UseRepo = $Repository}
		else {$UseRepo = $module.Repository}
		if ($module.Version -like 'Latest') {
			if ($AsNuGet) {
				try {
					Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Downloading"
					Write-Host '[Downloading] ' -NoNewline -ForegroundColor Yellow ; Write-Host 'NuGet: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name) " -ForegroundColor Green -NoNewline ; Write-Host "Path: $($Path)" -ForegroundColor DarkRed
					Save-Package -Name $module.Name -Provider NuGet -Source (Get-PSRepository -Name $UseRepo).SourceLocation -Path $Path.FullName | Out-Null
				} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
			} else {
				try {
					Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Downloading"
					Write-Host '[Downloading] ' -NoNewline -ForegroundColor Yellow ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name) " -ForegroundColor Green -NoNewline ; Write-Host "Path: $($Path)" -ForegroundColor DarkRed
					Save-Module -Name $module.name -Repository $UseRepo -Path $Path.FullName -Force -AcceptLicense
				} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
			}
		} else {
			if ($AsNuGet) {
				try {
					Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Downloading"
					Write-Host '[Downloading] ' -NoNewline -ForegroundColor Yellow ; Write-Host 'NuGet: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name)(ver $($module.version)) " -ForegroundColor Green -NoNewline ; Write-Host "Path: $($Path)" -ForegroundColor DarkRed
					Save-Package -Name $module.Name -Provider NuGet -Source (Get-PSRepository -Name $UseRepo).SourceLocation -RequiredVersion $module.Version -Path $Path.FullName | Out-Null
				} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
			} else {
				try {
					Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Downloading"
					Write-Host '[Downloading] ' -NoNewline -ForegroundColor Yellow ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name)(ver $($module.version)) " -ForegroundColor Green -NoNewline ; Write-Host "Path: $($Path)" -ForegroundColor DarkRed
					Save-Module -Name $module.name -Repository $UseRepo -RequiredVersion $module.Version -Path $Path.FullName -Force -AcceptLicense
				} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
			}

		}
	}
	
	if ($AddPathToPSModulePath) {
		try {
			$NugetCheck = Get-ChildItem -Path "$($Path.FullName)\*.nupkg"
			if (($env:PSModulePath.Split(';') -notcontains $Path.FullName) -and (-not($NugetCheck))) {
				$key = (Get-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager').OpenSubKey('Environment', $true)
				$regpath = $key.GetValue('PSModulePath', '', 'DoNotExpandEnvironmentNames')
				$regpath += ";$($path.FullName)"
				$key.SetValue('PSModulePath', $regpath, [Microsoft.Win32.RegistryValueKind]::ExpandString)
				Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Downloading"
				Write-Host '[Adding] ' -NoNewline -ForegroundColor Yellow ; Write-Host 'Path: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($path.FullName) " -ForegroundColor Green -NoNewline ; Write-Host 'to: $env:PSModulePath' -ForegroundColor Green
			} else {
				if ($NugetCheck) {Write-Warning "Can't add nuget repository to PSModulePath. Path needs to be extracted modules folders."}
				else {Write-Host '[Adding] ' -NoNewline -ForegroundColor Yellow ; Write-Host 'Path: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($path.FullName) " -ForegroundColor Green -NoNewline ; Write-Host 'to: $env:PSModulePath' -ForegroundColor Green -NoNewline; Write-Host ' - Already added.' -ForegroundColor DarkRed}
			}
		} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
	}
	Write-Verbose "[$(Get-Date -Format HH:mm:ss) DONE]"

}#end Function


$scriptblock = {
	param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
(Get-PWSHModuleList).name | Where-Object {$_ -like "*$wordToComplete*"}}
Register-ArgumentCompleter -CommandName Save-PWSHModule -ParameterName ListName -ScriptBlock $scriptBlock

$scriptblock1 = {
	(Get-PSRepository).Name
}
Register-ArgumentCompleter -CommandName Save-PWSHModule -ParameterName Repository -ScriptBlock $scriptBlock1

