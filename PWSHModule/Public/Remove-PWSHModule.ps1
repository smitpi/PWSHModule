
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

.PARAMETER ForceUninstallModules
Will uninstall the modules as well.

.EXAMPLE
Remove-PWSHModule -GitHubUserID smitpi -GitHubToken $GitHubToken -ListName base -ModuleName pslauncher
#>
Function Remove-PWSHModule {
	[Cmdletbinding(HelpURI = 'https://smitpi.github.io/PWSHModule/Remove-PWSHModule')]
	PARAM(
		[Parameter(Mandatory = $true)]
		[string]$GitHubUserID, 
		[Parameter(Mandatory = $true)]
		[string]$GitHubToken,
		[Parameter(Mandatory = $true)]
		[string]$ListName,
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[Alias('Name')]
		[string[]]$ModuleName,
		[ValidateScript( { $IsAdmin = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
				if ($IsAdmin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { $True }
				else { Throw 'Must be running an elevated prompt.' } })]
		[switch]$ForceUninstallModules
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

		try {
			Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Checking config file."
			$Content = (Invoke-WebRequest -Uri ($PRGist.files.$($ListName)).raw_url -Headers $headers).content | ConvertFrom-Json -ErrorAction Stop
		} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
		if ([string]::IsNullOrEmpty($Content.CreateDate) -or [string]::IsNullOrEmpty($Content.Modules)) {Write-Error 'Invalid Config File'}
		
		[System.Collections.ArrayList]$ModuleObject = @()		
		$Content.Modules | ForEach-Object {[void]$ModuleObject.Add($_)
		}
	}
	process {
		foreach ($mod in $ModuleName) {
			Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Find module to remove"
			$Modremove = ($Content.Modules | Where-Object {$_.Name -like "*$Mod*"})
			if ([string]::IsNullOrEmpty($Modremove) -or ($Modremove.name.count -gt 1)) {
				Write-Error 'Module not found. Redevine your search'
			} else {
				Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Removing module"
				$ModuleObject.Remove($Modremove)
				Write-Host '[Removed]' -NoNewline -ForegroundColor Yellow; Write-Host " $($Modremove.Name)" -NoNewline -ForegroundColor Cyan; Write-Host " from $($ListName)" -ForegroundColor Green
				if ($ForceUninstallModules) {
					try {
						Write-Host '[Uninstalling]' -NoNewline -ForegroundColor Yellow ; Write-Host 'All Versions of Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name) " -ForegroundColor Green
						Uninstall-Module -Name $mod -AllVersions -Force -ErrorAction Stop
					} catch {
						Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"
						Get-Module -Name $Mod -ListAvailable | ForEach-Object {
							try {
								Write-Host '[Deleting] ' -NoNewline -ForegroundColor Yellow ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($_.Name)($($_.Version)) " -ForegroundColor Green -NoNewline ; Write-Host "$($_.Path)" -ForegroundColor DarkRed
								Remove-Item (Get-Item $_.Path).Directory -Recurse -Force -ErrorAction Stop
							} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
						}
					}
				}	
			}
		}
	}
}
end {
	try {
		$Content.Modules = $ModuleObject | Sort-Object -Property name
		$Content.ModifiedDate = "$(Get-Date -Format u)"
		$content.ModifiedUser = "$($env:USERNAME.ToLower())@$($env:USERDNSDOMAIN.ToLower())"
		Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Uploading to gist"
		$Body = @{}
		$files = @{}
		$Files["$($PRGist.files.$($ListName).Filename)"] = @{content = ( $Content | ConvertTo-Json | Out-String ) }
		$Body.files = $Files
		$Uri = 'https://api.github.com/gists/{0}' -f $PRGist.id
		$json = ConvertTo-Json -InputObject $Body
		$json = [System.Text.Encoding]::UTF8.GetBytes($json)
		$null = Invoke-WebRequest -Headers $headers -Uri $Uri -Method Patch -Body $json -ErrorAction Stop
		Write-Host '[Uploaded] ' -NoNewline -ForegroundColor Yellow; Write-Host " List: $($ListName)" -NoNewline -ForegroundColor Cyan; Write-Host ' to Github Gist' -ForegroundColor Green
	} catch {Write-Error "Can't connect to gist:`n $($_.Exception.Message)"}
}
} #end Function


$scriptblock = {
	param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
	if ([bool]($PSDefaultParameterValues.Keys -like '*GitHubUserID*')) {(Show-PWSHModuleList).name}
}
Register-ArgumentCompleter -CommandName Remove-PWSHModule -ParameterName ListName -ScriptBlock $scriptBlock