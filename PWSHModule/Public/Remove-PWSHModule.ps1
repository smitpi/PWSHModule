
<#PSScriptInfo

.VERSION 0.1.0

.GUID c609d747-8b88-44c5-9f8b-da9e1c72acfd

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
Created [09/07/2022_15:58] Initial Script Creating

.PRIVATEDATA

#>


<#

.DESCRIPTION
 Remove a module to the config file

#>


<#
.SYNOPSIS
Remove module from the specified list.

.DESCRIPTION
Remove module from the specified list.

.PARAMETER GitHubUserID
The GitHub User ID.

.PARAMETER GitHubToken
GitHub Token with access to the Users' Gist.

.PARAMETER ListName
The File Name on GitHub Gist.

.PARAMETER ModuleName
Module to remove.

.PARAMETER UninstallModule
Will uninstall the modules as well.

.EXAMPLE
Remove-PWSHModule -ListName base -ModuleName pslauncher -GitHubUserID smitpi -GitHubToken $GitHubToken
#>
Function Remove-PWSHModule {
	[Cmdletbinding(SupportsShouldProcess = $true, HelpURI = 'https://smitpi.github.io/PWSHModule/Remove-PWSHModule')]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
	PARAM(
		[Parameter(Mandatory, ValueFromPipelineByPropertyName)]
		[string[]]$ListName,
		[Parameter(Mandatory,ValueFromPipelineByPropertyName)]
		[Alias('Name')]
		[string[]]$ModuleName,
		[Parameter(Mandatory)]
		[string]$GitHubUserID,
		[Parameter(Mandatory)]
		[string]$GitHubToken,
		[ValidateScript( { $IsAdmin = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
				if ($IsAdmin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { $True }
				else { Throw 'Must be running an elevated prompt.' } })]
		[switch]$UninstallModule
	)
	begin {
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
	}
	process {
		if ($pscmdlet.ShouldProcess('Target', 'Operation')) {
			foreach ($List in $ListName) {
				try {
					Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Checking config file."
					$Content = (Invoke-WebRequest -Uri ($PRGist.files.$($List)).raw_url -Headers $headers).content | ConvertFrom-Json -ErrorAction Stop
				} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
				if ([string]::IsNullOrEmpty($Content.CreateDate) -or [string]::IsNullOrEmpty($Content.Modules)) {Write-Error 'Invalid Config File'}

				[System.Collections.ArrayList]$ModuleObject = @()
				$Content.Modules | ForEach-Object {[void]$ModuleObject.Add($_)
				}
				foreach ($mod in $ModuleName) {
					Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Find module to remove"
					$Modremove = ($Content.Modules | Where-Object {$_.Name -like "*$Mod*"})
					if ([string]::IsNullOrEmpty($Modremove) -or ($Modremove.name.count -gt 1)) {
						Write-Error 'Module not found. Redefine your search'
					} else {
						Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Removing module"
						$ModuleObject.Remove($Modremove)
						Write-Host '[Removed]' -NoNewline -ForegroundColor Yellow; Write-Host " $($Modremove.Name)" -NoNewline -ForegroundColor Cyan; Write-Host " from $($ListName)" -ForegroundColor Green
						if ($UninstallModule) {
							try {
								Write-Host '[Uninstalling]' -NoNewline -ForegroundColor Yellow ; Write-Host 'All Versions of Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($mod) " -ForegroundColor Green
								Uninstall-Module -Name $mod -AllVersions -Force -ErrorAction Stop
							} catch {
								Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"
								Get-Module -Name $Mod -ListAvailable | ForEach-Object {
									try {
										Write-Host '[Deleting] ' -NoNewline -ForegroundColor Yellow ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($_.Name)($($_.Version)) " -ForegroundColor Green -NoNewline ; Write-Host "$($_.Path)" -ForegroundColor DarkRed
										$Directory = Join-Path -Path (Get-Item $_.Path).FullName -ChildPath '..\..\' -Resolve
										Remove-Item -Path $Directory -Recurse -Force -ErrorAction Stop
									} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
								}
							}
						}
					}
				}
				try {
					$Content.Modules = $ModuleObject | Sort-Object -Property name
					$Content.ModifiedDate = "$(Get-Date -Format u)"
					$content.ModifiedUser = "$($env:USERNAME.ToLower())"
					Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Uploading to gist"
					$Body = @{}
					$files = @{}
					$Files["$($PRGist.files.$($List).Filename)"] = @{content = ( $Content | ConvertTo-Json | Out-String ) }
					$Body.files = $Files
					$Uri = 'https://api.github.com/gists/{0}' -f $PRGist.id
					$json = ConvertTo-Json -InputObject $Body
					$json = [System.Text.Encoding]::UTF8.GetBytes($json)
					$null = Invoke-WebRequest -Headers $headers -Uri $Uri -Method Patch -Body $json -ErrorAction Stop
					Write-Host '[Uploaded] ' -NoNewline -ForegroundColor Yellow; Write-Host " List: $($List)" -NoNewline -ForegroundColor Cyan; Write-Host ' to Github Gist' -ForegroundColor Green
				} catch {Write-Error "Can't connect to gist:`n $($_.Exception.Message)"}
			}
		}
	}
	end {}
} #end Function


$scriptblock = {
	param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
	if ([bool]($PSDefaultParameterValues.Keys -like '*PWSHModule*:GitHubUserID')) {(Show-PWSHModuleList).name}
}
Register-ArgumentCompleter -CommandName Remove-PWSHModule -ParameterName ListName -ScriptBlock $scriptBlock

$scriptblock2 = {
	param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
	if (($PSDefaultParameterValues.Keys -like '*PWSHModule*:GitHubUserID')) {
	(Show-PWSHModule -ListName * -ErrorAction SilentlyContinue).name | Sort-Object -Unique
	}
}
Register-ArgumentCompleter -CommandName Remove-PWSHModule -ParameterName ModuleName -ScriptBlock $scriptBlock2