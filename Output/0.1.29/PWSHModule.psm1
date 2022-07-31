#region Public Functions
#region Add-PWSHModule.ps1
######## Function 1 of 10 ##################
# Function:         Add-PWSHModule
# Module:           PWSHModule
# ModuleVersion:    0.1.29
# Author:           Pierre Smit
# Company:          HTPCZA Tech
# CreatedOn:        2022/07/09 15:57:31
# ModifiedOn:       2022/07/31 12:36:20
# Synopsis:         Adds a new module to the GitHub Gist List.
#############################################
 
<#
.SYNOPSIS
Adds a new module to the GitHub Gist List.

.DESCRIPTION
Adds a new module to the GitHub Gist List.

.PARAMETER GitHubUserID
The GitHub User ID.

.PARAMETER GitHubToken
GitHub Token with access to the Users' Gist.

.PARAMETER ListName
The File Name on GitHub Gist.

.PARAMETER ModuleName
Name of the module to add. You can also use a keyword to search for.

.PARAMETER Repository
Name of the Repository to hosting the module.

.PARAMETER RequiredVersion
This will force a version to be used. Leave blank to use the latest version.

.EXAMPLE
Add-PWSHModule -GitHubUserID smitpi -GitHubToken $GitHubToken -ListName base -ModuleName pslauncher -Repository PSgallery -RequiredVersion 0.1.19

#>
Function Add-PWSHModule {
	[Cmdletbinding(HelpURI = 'https://smitpi.github.io/PWSHModule/Add-PWSHModule')]
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
		[String]$Repository = 'PSGallery',
		[string]$RequiredVersion
	)

	begin {
		try {
			Write-Verbose "[$(Get-Date -Format HH:mm:ss) BEGIN] Starting $($myinvocation.mycommand)"
			$headers = @{}
			$auth = '{0}:{1}' -f $GitHubUserID, $GitHubToken
			$bytes = [System.Text.Encoding]::ASCII.GetBytes($auth)
			$base64 = [System.Convert]::ToBase64String($bytes)
			$headers.Authorization = 'Basic {0}' -f $base64

			Write-Verbose "[$(Get-Date -Format HH:mm:ss) Starting connect to github"
			$url = 'https://api.github.com/users/{0}/gists' -f $GitHubUserID
			$AllGist = Invoke-RestMethod -Uri $url -Method Get -Headers $headers -ErrorAction Stop
			$PRGist = $AllGist | Select-Object | Where-Object { $_.description -like 'PWSHModule-ConfigFile' }
		} catch {Write-Error "Can't connect to gist:`n $($_.Exception.Message)"}

		try {
			Write-Verbose "[$(Get-Date -Format HH:mm:ss) Checking Config File"
			$Content = (Invoke-WebRequest -Uri ($PRGist.files.$($ListName)).raw_url -Headers $headers).content | ConvertFrom-Json -ErrorAction Stop
		} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
		if ([string]::IsNullOrEmpty($Content.CreateDate) -or [string]::IsNullOrEmpty($Content.Modules)) {Write-Error 'Invalid Config File'}

		[System.Collections.ArrayList]$ModuleObject = @()		
		$Content.Modules | ForEach-Object {[void]$ModuleObject.Add($_)}
	}
	process {
		foreach ($ModName in $ModuleName) {
			$index = 0
			Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Finding modules"
			$FilterMod = Find-Module -Filter $ModName -Repository $Repository | ForEach-Object {
				[PSCustomObject]@{
					Index       = $index
					Name        = $_.Name
					Version     = $_.version
					Description = $_.Description
					ProjectURI  = $_.ProjectUri.AbsoluteUri
				}
				$index++
			}

			if ($filtermod.name.count -gt 1) {
				Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] More than one module found"
				$FilterMod | Select-Object Index, Name, Description | Format-Table -AutoSize -Wrap
				$num = Read-Host 'Index Number '
				$ModuleToAdd = $filtermod[$num]
			} elseif ($filtermod.name.Count -eq 1) {
				$ModuleToAdd = $filtermod
			} else {Write-Error 'Module not found'}

			if ($RequiredVersion) {
				try {
					Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Looking for versions"
					$tmp = Find-Module -Name $ModuleToAdd.name -RequiredVersion $RequiredVersion -Repository $Repository -ErrorAction Stop
					$VersionToAdd = $RequiredVersion
				} catch {	
					$index = 0
					Find-Module -Name $ModuleToAdd.name -AllVersions -Repository $Repository | ForEach-Object {
						[PSCustomObject]@{
							Index   = $index
							Version = $_.Version
						}
						$index++
					} | Tee-Object -Variable Version | Format-Table
					$versionnum = Read-Host 'Index Number '
					$VersionToAdd = $version[$versionnum].Version
				}
			} else {$VersionToAdd = 'Latest'}

			Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Create new Object"
			
			if (-not($ModuleObject.Name.Contains($ModuleToAdd.Name))) {
				[void]$ModuleObject.Add([PSCustomObject]@{
						Name        = $ModuleToAdd.Name
						Version     = $VersionToAdd
						Description = $ModuleToAdd.Description
						Repository  = $Repository
						Projecturi  = $ModuleToAdd.ProjectUri
					})
				Write-Host '[Added]' -NoNewline -ForegroundColor Yellow; Write-Host " $($ModuleToAdd.Name)" -NoNewline -ForegroundColor Cyan; Write-Host " to $($ListName)" -ForegroundColor Green
			} else {
				Write-Host '[Duplicate]' -NoNewline -ForegroundColor DarkRed; Write-Host " $($ModuleToAdd.Name)" -NoNewline -ForegroundColor Cyan; Write-Host " to $($ListName)" -ForegroundColor Green
			}

		}
	}
	end {
		$Content.Modules = $ModuleObject | Sort-Object -Property name
		$Content.ModifiedDate = "$(Get-Date -Format u)"
		$content.ModifiedUser = "$($env:USERNAME.ToLower())@$($env:USERDNSDOMAIN.ToLower())"
		try {
			Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Uploading to gist"
			$Body = @{}
			$files = @{}
			$Files["$($PRGist.files.$($ListName).Filename)"] = @{content = ( $Content | ConvertTo-Json | Out-String ) }
			$Body.files = $Files
			$Uri = 'https://api.github.com/gists/{0}' -f $PRGist.id
			$json = ConvertTo-Json -InputObject $Body
			$json = [System.Text.Encoding]::UTF8.GetBytes($json)
			$null = Invoke-WebRequest -Headers $headers -Uri $Uri -Method Patch -Body $json -ErrorAction Stop
			Write-Host '[Uploaded]' -NoNewline -ForegroundColor Yellow; Write-Host " List: $($ListName)" -NoNewline -ForegroundColor Cyan; Write-Host ' to Github Gist' -ForegroundColor Green
		} catch {Write-Error "Can't connect to gist:`n $($_.Exception.Message)"}
		Write-Verbose "[$(Get-Date -Format HH:mm:ss) DONE]"
	}
} #end Function


$scriptblock = {
	(Get-PSRepository).Name
}
Register-ArgumentCompleter -CommandName Add-PWSHModule -ParameterName Repository -ScriptBlock $scriptBlock


$scriptblock = {
	param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
	if ([bool]($PSDefaultParameterValues.Keys -like '*GitHubUserID*')) {(Show-PWSHModuleList).name}
}
Register-ArgumentCompleter -CommandName Add-PWSHModule -ParameterName ListName -ScriptBlock $scriptBlock
 
Export-ModuleMember -Function Add-PWSHModule
#endregion
 
#region Add-PWSHModuleDefaultsToProfile.ps1
######## Function 2 of 10 ##################
# Function:         Add-PWSHModuleDefaultsToProfile
# Module:           PWSHModule
# ModuleVersion:    0.1.29
# Author:           Pierre Smit
# Company:          HTPCZA Tech
# CreatedOn:        2022/07/31 11:51:50
# ModifiedOn:       2022/07/31 13:00:02
# Synopsis:         Creates PSDefaultParameterValues in the users profile files.
#############################################
 
<#
.SYNOPSIS
Creates PSDefaultParameterValues in the users profile files.

.DESCRIPTION
Creates PSDefaultParameterValues in the users profile files.

.PARAMETER GitHubUserID
The GitHub User ID.

.PARAMETER PublicGist
Select if the list is hosted publicly.

.PARAMETER GitHubToken
GitHub Token with access to the Users' Gist.

.PARAMETER Scope
Where the module will be installed. AllUsers require admin access.

.EXAMPLE
Add-PWSHModuleDefaultsToProfile -GitHubUserID smitpi -PublicGist -Scope AllUsers

#>
Function Add-PWSHModuleDefaultsToProfile {
	[Cmdletbinding(DefaultParameterSetName = 'Public', HelpURI = 'https://smitpi.github.io/PWSHModule/Add-PWSHModuleDefaultsToProfile')]
	[OutputType([System.Object[]])]
	PARAM(
		[Parameter(Mandatory = $true)]
		[string]$GitHubUserID, 
		[Parameter(ParameterSetName = 'Public')]
		[switch]$PublicGist,
		[Parameter(ParameterSetName = 'Private')]
		[string]$GitHubToken,
		[ValidateSet('AllUsers', 'CurrentUser')]
		[string]$Scope
	)

	if ($PublicGist) {
		$PSDefaultParameterValues['*PWSHModule*:GitHubUserID'] = "$($GitHubUserID)"
		$PSDefaultParameterValues['*PWSHModule*:PublicGist'] = $true
		$PSDefaultParameterValues['*PWSHModule*:Scope'] = "$($Scope)"

		$ToAppend = @"

#region PWSHModule Defaults
`$PSDefaultParameterValues['*PWSHModule*:GitHubUserID'] = "$($GitHubUserID)"
`$PSDefaultParameterValues['*PWSHModule*:PublicGist'] = `$true
`$PSDefaultParameterValues['*PWSHModule*:Scope'] = "$($Scope)"
#endregion PWSHModule
"@
	} else {
		$PSDefaultParameterValues['*PWSHModule*:GitHubUserID'] = "$($GitHubUserID)"
		$PSDefaultParameterValues['*PWSHModule*:GitHubToken'] = "$($GitHubToken)"
		$PSDefaultParameterValues['*PWSHModule*:Scope'] = "$($Scope)"
		$ToAppend = @"
		
#region PWSHModule Defaults
`$PSDefaultParameterValues['*PWSHModule*:GitHubUserID'] =  "$($GitHubUserID)"
`$PSDefaultParameterValues['*PWSHModule*:GitHubToken'] =  "$($GitHubToken)"
`$PSDefaultParameterValues['*PWSHModule*:Scope'] =  "$($Scope)"
#endregion PWSHModule
"@
	}

	try {
		$CheckProfile = Get-Item $PROFILE -ErrorAction Stop
	} catch { $CheckProfile = New-Item $PROFILE -ItemType File -Force}
	
	$Files = Get-ChildItem -Path "$($CheckProfile.Directory)\*profile*"
	foreach ($file in $files) {	
		$tmp = Get-Content -Path $file.FullName | Where-Object { $_ -notlike '*PWSHModule*'}
		$tmp | Set-Content -Path $file.FullName -Force
		Add-Content -Value $ToAppend -Path $file.FullName -Force -Encoding utf8
		Write-Host '[Updated]' -NoNewline -ForegroundColor Yellow; Write-Host ' Profile File:' -NoNewline -ForegroundColor Cyan; Write-Host " $($file.FullName)" -ForegroundColor Green
	}

} #end Function
 
Export-ModuleMember -Function Add-PWSHModuleDefaultsToProfile
#endregion
 
#region Install-PWSHModule.ps1
######## Function 3 of 10 ##################
# Function:         Install-PWSHModule
# Module:           PWSHModule
# ModuleVersion:    0.1.29
# Author:           Pierre Smit
# Company:          HTPCZA Tech
# CreatedOn:        2022/07/12 07:38:48
# ModifiedOn:       2022/07/31 12:36:20
# Synopsis:         Install modules from the specified list.
#############################################
 
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
					Install-Module -Name $module.Name -Repository $module.Repository -Scope $Scope -Force -AllowClobber -SkipPublisherCheck
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
							Install-Module -Name $module.name -Scope $Scope -Repository $module.Repository -AllowClobber -Force -SkipPublisherCheck
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
					Install-Module -Name $module.Name -Repository $module.Repository -RequiredVersion $module.Version -Scope $Scope -Force -AllowClobber
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
	if ([bool]($PSDefaultParameterValues.Keys -like '*GitHubUserID*')) {(Show-PWSHModuleList).name}
}
Register-ArgumentCompleter -CommandName Install-PWSHModule -ParameterName ListName -ScriptBlock $scriptBlock
 
Export-ModuleMember -Function Install-PWSHModule
#endregion
 
#region New-PWSHModuleList.ps1
######## Function 4 of 10 ##################
# Function:         New-PWSHModuleList
# Module:           PWSHModule
# ModuleVersion:    0.1.29
# Author:           Pierre Smit
# Company:          HTPCZA Tech
# CreatedOn:        2022/07/09 15:22:20
# ModifiedOn:       2022/07/31 11:58:00
# Synopsis:         Add a new list to GitHub Gist.
#############################################
 
<#
.SYNOPSIS
Add a new list to GitHub Gist.

.DESCRIPTION
Add a new list to GitHub Gist.

.PARAMETER GitHubUserID
The GitHub User ID.

.PARAMETER GitHubToken
GitHub Token with access to the Users' Gist.

.PARAMETER ListName
The File Name on GitHub Gist.

.PARAMETER Description
Summary of the function for the list.

.EXAMPLE
New-PWSHModuleList -GitHubUserID smitpi -GitHubToken $GitHubToken -ListName Base -Description "These modules needs to be installed on all servers"

#>
Function New-PWSHModuleList {
	[Cmdletbinding( HelpURI = 'https://smitpi.github.io/PWSHModule/New-PWSHModuleList')]
	PARAM(
		[Parameter(Mandatory = $true)]
		[string]$GitHubUserID, 
		[Parameter(Mandatory = $true)]
		[string]$GitHubToken,
		[Parameter(Mandatory = $true)]
		[string]$ListName,
		[Parameter(Mandatory = $true)]
		[string]$Description
	)

	Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Creating config"
	$NewConfig = [PSCustomObject]@{
		CreateDate   = (Get-Date -Format u)
		Description  = $Description
		Author       = "$($env:USERNAME.ToLower())@$($env:USERDNSDOMAIN.ToLower())"
		ModifiedDate = 'Unknown'
		ModifiedUser = 'Unknown'
		Modules      = [PSCustomObject]@{
			Name        = 'PWSHModule'
			Version     = 'Latest'
			Description = 'Uses a GitHub Gist File to install and maintain a list of PowerShell Modules'
			Repository  = 'PSGallery'
			Projecturi  = 'https://github.com/smitpi/PWSHModule'
		}
 } | ConvertTo-Json

	$ConfigFile = Join-Path $env:TEMP -ChildPath "$($ListName).json"
	Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Create temp file"
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

		
	if ([string]::IsNullOrEmpty($PRGist)) {
		try {
			Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Uploading to gist"
			$Body = @{}
			$files = @{}
			$Files["$($ListName)"] = @{content = ( Get-Content (Get-Item $ConfigFile).FullName -Encoding UTF8 | Out-String ) }
			$Body.files = $Files
			$Body.description = 'PWSHModule-ConfigFile'
			$json = ConvertTo-Json -InputObject $Body
			$json = [System.Text.Encoding]::UTF8.GetBytes($json)
			$null = Invoke-WebRequest -Headers $headers -Uri https://api.github.com/gists -Method Post -Body $json -ErrorAction Stop
			Write-Host '[Uploaded]' -NoNewline -ForegroundColor Yellow; Write-Host " $($ListName).json" -NoNewline -ForegroundColor Cyan; Write-Host ' to Github Gist' -ForegroundColor Green

		} catch {Write-Error "Can't connect to gist:`n $($_.Exception.Message)"}
	} else {
		try {
			Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Uploading to Gist"
			$Body = @{}
			$files = @{}
			$Files["$($ListName)"] = @{content = ( Get-Content (Get-Item $ConfigFile).FullName -Encoding UTF8 | Out-String ) }
			$Body.files = $Files
			$Uri = 'https://api.github.com/gists/{0}' -f $PRGist.id
			$json = ConvertTo-Json -InputObject $Body
			$json = [System.Text.Encoding]::UTF8.GetBytes($json)
			$null = Invoke-WebRequest -Headers $headers -Uri $Uri -Method Patch -Body $json -ErrorAction Stop
			Write-Host '[Uploaded]' -NoNewline -ForegroundColor Yellow; Write-Host " $($ListName).json" -NoNewline -ForegroundColor Cyan; Write-Host ' to Github Gist' -ForegroundColor Green
		} catch {Write-Error "Can't connect to gist:`n $($_.Exception.Message)"}
	}
	Write-Verbose "[$(Get-Date -Format HH:mm:ss) DONE]"


} #end Function
 
Export-ModuleMember -Function New-PWSHModuleList
#endregion
 
#region Remove-PWSHModule.ps1
######## Function 5 of 10 ##################
# Function:         Remove-PWSHModule
# Module:           PWSHModule
# ModuleVersion:    0.1.29
# Author:           Pierre Smit
# Company:          HTPCZA Tech
# CreatedOn:        2022/07/13 11:14:06
# ModifiedOn:       2022/07/31 12:36:20
# Synopsis:         Remove module from the specified list.
#############################################
 
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

.PARAMETER UninstallModules
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
		[switch]$UninstallModules
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
			$Modremove = ($Content.Modules | Where-Object {$_.Name -like $Mod})
			if ([string]::IsNullOrEmpty($Modremove) -or ($Modremove.name.count -gt 1)) {
				Write-Error 'Module not found'
			} else {
				Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Removing module"
				$ModuleObject.Remove($Modremove)
				Write-Host '[Removed]' -NoNewline -ForegroundColor Yellow; Write-Host " $($Modremove.Name)" -NoNewline -ForegroundColor Cyan; Write-Host " from $($ListName)" -ForegroundColor Green
				if ($UninstallModules) {Uninstall-PWSHModule -GitHubUserID $GitHubUserID -GitHubToken $GitHubToken -ListName $ListName -ModuleName $Modremove.Name -ForceDeleteFolder}
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
	if ([bool]($PSDefaultParameterValues.Keys	 -like "*GitHubUserID*")) {(Show-PWSHModuleList).name}
}
Register-ArgumentCompleter -CommandName Remove-PWSHModule -ParameterName ListName -ScriptBlock $scriptBlock
 
Export-ModuleMember -Function Remove-PWSHModule
#endregion
 
#region Remove-PWSHModuleList.ps1
######## Function 6 of 10 ##################
# Function:         Remove-PWSHModuleList
# Module:           PWSHModule
# ModuleVersion:    0.1.29
# Author:           Pierre Smit
# Company:          HTPCZA Tech
# CreatedOn:        2022/07/31 11:14:51
# ModifiedOn:       2022/07/31 12:35:30
# Synopsis:         Deletes a list from GitHub Gist
#############################################
 
<#
.SYNOPSIS
Deletes a list from GitHub Gist

.DESCRIPTION
Deletes a list from GitHub Gist

.PARAMETER GitHubUserID
The GitHub User ID.

.PARAMETER GitHubToken
GitHub Token with access to the Users' Gist.

.PARAMETER ListName
The Name of the list to remove.

.EXAMPLE
Remove-PWSHModuleList -GitHubUserID smitpi -GitHubToken $GitHubToken -ListName Base

#>
Function Remove-PWSHModuleList {
	[Cmdletbinding(HelpURI = 'https://smitpi.github.io/PWSHModule/Remove-PWSHModuleList')]
	[OutputType([System.Object[]])]
	PARAM(
		[Parameter(Mandatory = $true)]
		[string]$GitHubUserID, 
		[Parameter(Mandatory = $true)]
		[string]$GitHubToken,
		[Parameter(Mandatory = $true)]
		[string]$ListName
	)

	try {
		Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Connect to gist"
		$headers = @{}
		$auth = '{0}:{1}' -f $GitHubUserID, $GitHubToken
		$bytes = [System.Text.Encoding]::ASCII.GetBytes($auth)
		$base64 = [System.Convert]::ToBase64String($bytes)
		$headers.Authorization = 'Basic {0}' -f $base64

		$url = 'https://api.github.com/users/{0}/gists' -f $GitHubUserID
		$AllGist = Invoke-RestMethod -Uri $url -Method Get -Headers $headers -ErrorAction Stop
		$PRGist = $AllGist | Select-Object | Where-Object { $_.description -like 'PWSHModule-ConfigFile' }
	} catch {throw "Can't connect to gist:`n $($_.Exception.Message)"}


	Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Create object"
	$CheckExist = $PRGist.files | Get-Member -MemberType NoteProperty | Where-Object {$_.name -like $ListName}
	if (-not([string]::IsNullOrEmpty($CheckExist))) {
		try {
			Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Remove list from Gist"
			$Body = @{}
			$files = @{}
			$Files["$($ListName)"] = $null
			$Body.files = $Files
			$Uri = 'https://api.github.com/gists/{0}' -f $PRGist.id
			$json = ConvertTo-Json -InputObject $Body
			$json = [System.Text.Encoding]::UTF8.GetBytes($json)
			$null = Invoke-WebRequest -Headers $headers -Uri $Uri -Method Patch -Body $json -ErrorAction Stop
			Write-Host '[Removed]' -NoNewline -ForegroundColor Yellow; Write-Host " $($ListName)" -NoNewline -ForegroundColor Cyan; Write-Host ' from Github Gist' -ForegroundColor DarkRed
			Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] updated gist."
		} catch {Write-Error "Can't connect to gist:`n $($_.Exception.Message)"}
	}
	Write-Verbose "[$(Get-Date -Format HH:mm:ss) DONE]"
} #end Function

$scriptblock = {
	param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
	if ([bool]($PSDefaultParameterValues.Keys -like '*GitHubUserID*')) {(Show-PWSHModuleList).name}
}
Register-ArgumentCompleter -CommandName Remove-PWSHModuleList -ParameterName ListName -ScriptBlock $scriptBlock
 
Export-ModuleMember -Function Remove-PWSHModuleList
#endregion
 
#region Save-PWSHModule.ps1
######## Function 7 of 10 ##################
# Function:         Save-PWSHModule
# Module:           PWSHModule
# ModuleVersion:    0.1.29
# Author:           Pierre Smit
# Company:          HTPCZA Tech
# CreatedOn:        2022/07/13 10:26:41
# ModifiedOn:       2022/07/31 12:37:23
# Synopsis:         Saves the modules from the specified list to a folder.
#############################################
 
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
Save-PWSHModule -GitHubUserID smitpi -GitHubToken $GitHubToken -ListName extended -AsNuGet -Path c:\temp\

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
	if ([bool]($PSDefaultParameterValues.Keys	 -like "*GitHubUserID*")) {(Show-PWSHModuleList).name}
}
Register-ArgumentCompleter -CommandName Save-PWSHModule -ParameterName ListName -ScriptBlock $scriptBlock
 
Export-ModuleMember -Function Save-PWSHModule
#endregion
 
#region Show-PWSHModule.ps1
######## Function 8 of 10 ##################
# Function:         Show-PWSHModule
# Module:           PWSHModule
# ModuleVersion:    0.1.29
# Author:           Pierre Smit
# Company:          HTPCZA Tech
# CreatedOn:        2022/07/09 15:57:20
# ModifiedOn:       2022/07/31 13:22:23
# Synopsis:         Show the details of the modules in a list.
#############################################
 
<#
.SYNOPSIS
Show the details of the modules in a list.

.DESCRIPTION
Show the details of the modules in a list.

.PARAMETER GitHubUserID
The GitHub User ID.

.PARAMETER PublicGist
Select if the list is hosted publicly.

.PARAMETER GitHubToken
GitHub Token with access to the Users' Gist.

.PARAMETER ListName
The File Name on GitHub Gist.

.PARAMETER CompareInstalled
Compare the list to what is installed.

.PARAMETER ShowProjectURI
Will open the browser to the the project URL.

.EXAMPLE
Show-PWSHModule -GitHubUserID smitpi -GitHubToken $GitHubToken -ListName Base

#>
Function Show-PWSHModule {
	[Cmdletbinding(DefaultParameterSetName = 'Private', HelpURI = 'https://smitpi.github.io/PWSHModule/Show-PWSHModule')]
	PARAM(
		[Parameter(Mandatory = $true)]
		[string]$GitHubUserID, 
		[Parameter(ParameterSetName = 'Public')]
		[switch]$PublicGist,
		[Parameter(ParameterSetName = 'Private')]
		[string]$GitHubToken,
		[Parameter(Mandatory = $true)]
		[string]$ListName,
		[switch]$CompareInstalled,
		[switch]$ShowProjectURI
	)

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
	} catch {throw "Can't connect to gist:`n $($_.Exception.Message)"}

	try {
		Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Checking config file"
		$Content = (Invoke-WebRequest -Uri ($PRGist.files.$($Listname)).raw_url -Headers $headers).content | ConvertFrom-Json -ErrorAction Stop
	} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
	if ([string]::IsNullOrEmpty($Content.CreateDate) -or [string]::IsNullOrEmpty($Content.Modules)) {Throw 'Invalid Config File'}

	$index = 0
	Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Creating object"
	[System.Collections.ArrayList]$ModuleObject = @()		
	$Content.Modules | ForEach-Object {				
		[void]$ModuleObject.Add([PSCustomObject]@{
				Index       = $index
				Name        = $_.Name
				Version     = $_.version
				Description = $_.Description
				Repository  = $_.Repository
				Projecturi  = $_.projecturi
			})
		$index++
	}

	if ($CompareInstalled) {
		[System.Collections.ArrayList]$CompareObject = @()		
		$index = 0
		foreach ($CompareModule in $ModuleObject) {
			try {
				Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Online: $($CompareModule.name)"
				if ($CompareModule.Version -like 'Latest') {
					$online = Find-Module -Name $CompareModule.name -Repository $CompareModule.Repository 
				} else {
					$online = Find-Module -Name $CompareModule.name -Repository $CompareModule.Repository -RequiredVersion $CompareModule.Version
				}
				Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Local: $($CompareModule.name)"
				$local = $null
				$local = Get-Module -Name $CompareModule.Name -ListAvailable | Sort-Object -Property Version -Descending | Select-Object -First 1
				if ([string]::IsNullOrEmpty($local)) {
					$InstallVer = 'NotInstalled'
					$InstallCount = 'NotInstalled'
					$InstallFolder = 'NotInstalled'
				} else {
					$InstallVer = $local.Version
					$InstallCount = (Get-Module -Name $CompareModule.Name -ListAvailable).count
					$InstallFolder = (Get-Item $local.Path).DirectoryName
				}
				if ($local.Version -lt $online.Version) {$update = $true}
				else {$update = $false}
				Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Building List with module: $($CompareModule.name)"
				[void]$CompareObject.Add([PSCustomObject]@{
						Index           = $index
						Name            = $CompareModule.Name
						InstalledVer    = $InstallVer
						OnlineVer       = $online.Version
						UpdateAvailable = $update
						InstallCount    = $InstallCount
						Folder          = $InstallFolder
						Description     = $CompareModule.Description
						Repository      = $CompareModule.Repository
					})
			} catch {Write-Warning "Error $($CompareModule.Name): `n`tMessage:$($_.Exception.Message)"}
			$index++
		}
		$CompareObject
	} else {$ModuleObject}
	if ($ShowProjectURI) {
		Write-Output ' '
		[int]$IndexURI = Read-Host 'Module Index Number'
		if (-not([string]::IsNullOrEmpty($Content.Modules[$IndexURI].projecturi))) {
			Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] open url"
			Start-Process "$($Content.Modules[$IndexURI].projecturi)"
		} else { Write-Warning 'NotInstalled ProjectURI'}
		Write-Verbose "[$(Get-Date -Format HH:mm:ss) DONE]"
	}
} #end Function


$scriptblock = {
	param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
	if ([bool]($PSDefaultParameterValues.Keys -like '*GitHubUserID*')) {(Show-PWSHModuleList).name}
}
Register-ArgumentCompleter -CommandName Show-PWSHModule -ParameterName ListName -ScriptBlock $scriptBlock
 
Export-ModuleMember -Function Show-PWSHModule
#endregion
 
#region Show-PWSHModuleList.ps1
######## Function 9 of 10 ##################
# Function:         Show-PWSHModuleList
# Module:           PWSHModule
# ModuleVersion:    0.1.29
# Author:           Pierre Smit
# Company:          HTPCZA Tech
# CreatedOn:        2022/07/13 01:15:39
# ModifiedOn:       2022/07/20 17:59:55
# Synopsis:         List all the GitHub Gist Lists.
#############################################
 
<#
.SYNOPSIS
List all the GitHub Gist Lists.

.DESCRIPTION
List all the GitHub Gist Lists.

.PARAMETER GitHubUserID
The GitHub User ID.

.PARAMETER PublicGist
Select if the list is hosted publicly.

.PARAMETER GitHubToken
GitHub Token with access to the Users' Gist.

.EXAMPLE
Show-PWSHModuleList -GitHubUserID smitpi -GitHubToken $GitHubToken 

#>
Function Show-PWSHModuleList {
	[Cmdletbinding(DefaultParameterSetName = 'Private', HelpURI = 'https://smitpi.github.io/PWSHModule/Show-PWSHModuleList')]
	PARAM(
		[Parameter(Mandatory = $true)]
		[string]$GitHubUserID, 
		[Parameter(ParameterSetName = 'Public')]
		[switch]$PublicGist,
		[Parameter(ParameterSetName = 'Private')]
		[string]$GitHubToken
	)

	
	try {
		Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Connect to gist"
		$headers = @{}
		$auth = '{0}:{1}' -f $GitHubUserID, $GitHubToken
		$bytes = [System.Text.Encoding]::ASCII.GetBytes($auth)
		$base64 = [System.Convert]::ToBase64String($bytes)
		$headers.Authorization = 'Basic {0}' -f $base64

		$url = 'https://api.github.com/users/{0}/gists' -f $GitHubUserID
		$AllGist = Invoke-RestMethod -Uri $url -Method Get -Headers $headers -ErrorAction Stop
		$PRGist = $AllGist | Select-Object | Where-Object { $_.description -like 'PWSHModule-ConfigFile' }
	} catch {throw "Can't connect to gist:`n $($_.Exception.Message)"}


	[System.Collections.ArrayList]$GistObject = @()
	Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Create object"
	$PRGist.files | Get-Member -MemberType NoteProperty | ForEach-Object {
		$Content = (Invoke-WebRequest -Uri ($PRGist.files.$($_.name)).raw_url -Headers $headers).content | ConvertFrom-Json -ErrorAction Stop
		if ($Content.modifiedDate -notlike 'Unknown') {
			$modifiedDate = [datetime]$Content.ModifiedDate
			$modifiedUser = $Content.ModifiedUser
		} else { 
			$modifiedDate = 'Unknown'
			$modifiedUser = 'Unknown'
		}
		[void]$GistObject.Add([PSCustomObject]@{
				Name         = $_.Name
				Description  = $Content.Description
				Date         = [datetime]$Content.CreateDate
				Author       = $Content.Author
				ModifiedDate = $modifiedDate
				ModifiedUser = $modifiedUser
			})
	}

	$GistObject
	Write-Verbose "[$(Get-Date -Format HH:mm:ss) DONE]"

} #end Function
 
Export-ModuleMember -Function Show-PWSHModuleList
#endregion
 
#region Uninstall-PWSHModule.ps1
######## Function 10 of 10 ##################
# Function:         Uninstall-PWSHModule
# Module:           PWSHModule
# ModuleVersion:    0.1.29
# Author:           Pierre Smit
# Company:          HTPCZA Tech
# CreatedOn:        2022/07/20 19:06:13
# ModifiedOn:       2022/07/31 01:29:01
# Synopsis:         Will uninstall the module from the system.
#############################################
 
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

.PARAMETER ModuleName
Name of the module to uninstall. Use * to select all modules in the list.

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
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[Alias('Name')]
		[string[]]$ModuleName,
		[switch]$OldVersions,
		[switch]$ForceDeleteFolder
	)

	begin {
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
		[System.Collections.ArrayList]$CollectObject = @()
	}
	process {
		
		foreach ($collectmod in $ModuleName) {
			$Content.Modules | Where-Object {$_.name -like $collectmod} | ForEach-Object {[void]$CollectObject.Add($_)}
		}
		#$mods = Get-Module -list | Where-Object path -NotMatch 'windows\\system32' | Group-Object -Property name | Where-Object count -GT 1
		#$mods | ForEach-Object { $_.group | Select-Object -Skip 1 } | ForEach-Object { Uninstall-Module -Name $_.name -RequiredVersion $_.version -WhatIf }
	}
	end {
		foreach ($module in $CollectObject) {
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
					Uninstall-Module -Name $module.Name -AllVersions -Force -ErrorAction Stop
				} catch {
					Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"
					if ($ForceDeleteFolder) {
						Get-Module -Name $Module.name -ListAvailable | ForEach-Object {
							try {
								Write-Host '[Deleting] ' -NoNewline -ForegroundColor Yellow ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($_.Name)($($_.Version)) " -ForegroundColor Green -NoNewline ; Write-Host "$($_.Path)" -ForegroundColor DarkRed
								Get-ChildItem -Path (Get-Item $_.Path).Directory -Recurse | Remove-Item -Force -Recurse
							} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
						}
						
					}
				}
			}
			Write-Verbose "[$(Get-Date -Format HH:mm:ss) DONE]"
		}
	}
} #end Function


$scriptblock = {
	param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
	if (($PSDefaultParameterValues.Keys -like '*GitHubUserID*')) {(Show-PWSHModuleList).name}
}
Register-ArgumentCompleter -CommandName Uninstall-PWSHModule -ParameterName ListName -ScriptBlock $scriptBlock
 
Export-ModuleMember -Function Uninstall-PWSHModule
#endregion
 
#endregion
 
