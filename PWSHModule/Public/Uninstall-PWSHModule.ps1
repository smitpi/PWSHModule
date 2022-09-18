
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

.PARAMETER ListName
The File Name on GitHub Gist.

.PARAMETER ModuleName
Name of the module to uninstall. Use * to select all modules in the list.

.PARAMETER UninstallOldVersions
Will uninstall old versions of All modules.

.PARAMETER ForceUninstall
Will force delete the base folder if uninstall fail.

.PARAMETER GitHubUserID
The GitHub User ID.

.PARAMETER PublicGist
Select if the list is hosted publicly.

.PARAMETER GitHubToken
GitHub Token with access to the Users' Gist.

.EXAMPLE
Uninstall-PWSHModule  -ListName base -OldVersions -GitHubUserID smitpi -PublicGist

#>
Function Uninstall-PWSHModule {
	[Cmdletbinding(DefaultParameterSetName = 'Private', HelpURI = 'https://smitpi.github.io/PWSHModule/Install-PWSHModule')]
	PARAM(
		[Parameter(Position = 0, Mandatory, ParameterSetName = 'List')]
		[ValidateScript( { $IsAdmin = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
				if ($IsAdmin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { $True }
				else { Throw 'Must be running an elevated prompt.' } })]
		[string[]]$ListName,

		[Parameter(Position = 1, Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'List')]
		[Alias('Name')]
		[string[]]$ModuleName,

		[Parameter(Position = 0, ParameterSetName = 'OldVersions')]
		[switch]$UninstallOldVersions,

		[Parameter(Position = 1, ParameterSetName = 'OldVersions')]
		[switch]$ForceUninstall,

		[Parameter(Mandatory, ParameterSetName = 'List')]
		[string]$GitHubUserID,

		[Parameter(ParameterSetName = 'Public')]
		[Parameter(ParameterSetName = 'List')]
		[switch]$PublicGist,

		[Parameter(ParameterSetName = 'Private')]
		[Parameter(ParameterSetName = 'List')]
		[string]$GitHubToken
	)

	begin {
		if (-not($UninstallOldVersions)) {
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
		}
	}
	process {
		foreach ($List in $ListName) {
			try {
				Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Checking Config File"
				$Content = (Invoke-WebRequest -Uri ($PRGist.files.$($List)).raw_url -Headers $headers).content | ConvertFrom-Json -ErrorAction Stop
			} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
			if ([string]::IsNullOrEmpty($Content.CreateDate) -or [string]::IsNullOrEmpty($Content.Modules)) {Write-Error 'Invalid Config File'}
			[System.Collections.ArrayList]$CollectObject = @()

			foreach ($collectmod in $ModuleName) {
				$Content.Modules | Where-Object {$_.name -like $collectmod} | ForEach-Object {[void]$CollectObject.Add($_)}
			}
			
		}
	}
	end {
		foreach ($module in ($CollectObject | Select-Object -Unique) ) {
			Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Checking for installed module"
			try {
				Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Uninstalling module $($module.Name)"
				Write-Host '[Uninstalling]' -NoNewline -ForegroundColor Yellow ; Write-Host 'All Versions of Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name) " -ForegroundColor Green
				Uninstall-Module -Name $module.Name -AllVersions -Force -ErrorAction Stop
			} catch { Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
		}
		Write-Verbose "[$(Get-Date -Format HH:mm:ss) DONE]"
	
		if ($UninstallOldVersions) {
			Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Checking for duplicate module"
			$DuplicateMods = Get-Module -list | Where-Object path -NotMatch 'windows\\system32' | Group-Object -Property name | Where-Object count -GT 1
			foreach ($Duplicate in $DuplicateMods) {
				$Duplicate.Group | Sort-Object -Property version -Descending | Select-Object -Skip 1 | ForEach-Object {
					Write-Host '[Uninstalling]' -NoNewline -ForegroundColor Yellow ; Write-Host ' Duplicate Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($Duplicate.Name) " -ForegroundColor Green -NoNewline ; Write-Host " [$($_.version)] - $($_.path) " -ForegroundColor DarkRed
					Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Uninstalling duplicate $($Duplicate.Name) $($_.Path)"
					try {
						Uninstall-Module -Name $Duplicate.Name -RequiredVersion $_.Version -Force -AllowPrerelease -ErrorAction Stop
					} catch {
						Write-Warning "Uninstall for module $($Duplicate.Name) Failed.`n`tMessage:$($_.Exception.Message)"
						if ($ForceUninstall) {
							try {
								Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Uninstalling duplicate $($Duplicate.Name) $($_.Path) - Force delete folder"
								$Modpath = Get-Item (Join-Path $Duplicate.Group[1].Path -ChildPath '..\' -Resolve)
								$Modpath | Remove-Item -Recurse -Force
							} catch { Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
						}
					}
				}
				Write-Verbose "[$(Get-Date -Format HH:mm:ss) DONE] $($Duplicate.Name)"
			}
		}
	}
} #end Function


$scriptblock = {
	param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
(Get-PWSHModuleList).name | Where-Object {$_ -like "*$wordToComplete*"}}
Register-ArgumentCompleter -CommandName Uninstall-PWSHModule -ParameterName ListName -ScriptBlock $scriptBlock

$scriptblock2 = {
	param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
	if (($PSDefaultParameterValues.Keys -like '*:GitHubUserID')) {
	(Show-PWSHModule -ListName $fakeBoundParameters.Listname -ErrorAction SilentlyContinue).name | Where-Object {$_ -like "*$wordToComplete*"}
	}
}
Register-ArgumentCompleter -CommandName Uninstall-PWSHModule -ParameterName ModuleName -ScriptBlock $scriptBlock2

