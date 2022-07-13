﻿#region Private Functions
#region DisplayOutput.ps1
########### Private Function ###############
# Source:           DisplayOutput.ps1
# Module:           PWSHModule
# ModuleVersion:    0.1.2
# Company:          HTPCZA Tech
# CreatedOn:        2022/07/11 14:18:33
# ModifiedOn:       2022/07/11 14:36:56
############################################
function DisplayOutput {
	PARAM($arg)
	$index = 0
	$NLenght = ($arg | ForEach-Object {$_.name.length} | Sort-Object -Descending)[0] + 3
	$VLenght = ($arg | ForEach-Object {$_.version.length} | Sort-Object -Descending)[0] + 3
	$DescLength = $Host.UI.RawUI.WindowSize.Width - 30 - $($NLenght)

	Write-Host ('{0,2})' -f 'I') -NoNewline -ForegroundColor Gray
	Write-Host ("{0,-$($VLenght)}" -f 'Version') -NoNewline -ForegroundColor DarkRed
	Write-Host ("{0,-$($NLenght)}" -f 'Name') -NoNewline -ForegroundColor Cyan
	Write-Host ('{0}' -f 'Description') -ForegroundColor DarkYellow

	foreach ($module in $arg) {
		Write-Host ('{0,2})' -f $index) -NoNewline -ForegroundColor Gray
		Write-Host ("{0,-$($VLenght)}" -f "[$($module.Version)]") -NoNewline -ForegroundColor DarkRed
		Write-Host ("{0,-$($NLenght)}" -f $module.Name) -NoNewline -ForegroundColor Cyan
		Write-Host ('{0}...' -f ($module.Description[0..$($DescLength)] | Join-String)) -ForegroundColor DarkYellow
		$index++
	}
}
#endregion
#endregion
 
#region Public Functions
#region Add-PWSHModule.ps1
######## Function 1 of 6 ##################
# Function:         Add-PWSHModule
# Module:           PWSHModule
# ModuleVersion:    0.1.2
# Author:           Pierre Smit
# Company:          HTPCZA Tech
# CreatedOn:        2022/07/09 15:57:31
# ModifiedOn:       2022/07/13 05:36:50
# Synopsis:         Adds a new module to the GitHub Gist List.
#############################################
 
<#
.SYNOPSIS
Add a Module name to the config File.

.DESCRIPTION
Add a Module name to the config File.

.PARAMETER Path
Path to the json config file.

.PARAMETER ModuleName
Name of the Module to add.

.PARAMETER Repository
Repository to find the module.

.PARAMETER RequiredVersion
Select if you want to specify a specific version.

.EXAMPLE
Add-PWSHModule -Path C:\Utils\PWSLModule.json -ModuleName Json -Repository PSGallery

#>

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
			$Content = (Invoke-WebRequest -Uri ($PRGist.files.$($ListName)).raw_url -Headers $headers).content | ConvertFrom-Json -ErrorAction Stop
		} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
		if ([string]::IsNullOrEmpty($Content.CreateDate) -or [string]::IsNullOrEmpty($Content.Modules)) {Write-Error 'Invalid Config File'}

		[System.Collections.ArrayList]$ModuleObject = @()		
		$Content.Modules | ForEach-Object {[void]$ModuleObject.Add($_)}
	}
	process {
		foreach ($ModName in $ModuleName) {
			$index = 0
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
				$FilterMod | Select-Object Index, Name, Description | Format-Table -AutoSize -Wrap
				$num = Read-Host 'Index Number '
				$ModuleToAdd = $filtermod[$num]
			} elseif ($filtermod.name.Count -eq 1) {
				$ModuleToAdd = $filtermod
			} else {Write-Error 'Module not found'}

			if ($RequiredVersion) {
				try {
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

			[void]$ModuleObject.Add([PSCustomObject]@{
					Name        = $ModuleToAdd.Name
					Version     = $VersionToAdd
					Description = $ModuleToAdd.Description
					Repository  = $Repository
					Projecturi  = $ModuleToAdd.ProjectUri
				})
			Write-Host '[Added]' -NoNewline -ForegroundColor Yellow; Write-Host " $($ModuleToAdd.Name)" -NoNewline -ForegroundColor Cyan; Write-Host " to $($ListName)" -ForegroundColor Green
		}
	}
	end {
		$Content.Modules = $ModuleObject | Sort-Object -Property name
		$Content.Modified = "[$(Get-Date -Format u)] -- $($env:USERNAME.ToLower())@$($env:USERDNSDOMAIN.ToLower())"
		try {
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
	}
} #end Function


$scriptblock = {
	param($commandName, $parameterName, $stringMatch)
	(Get-PSRepository).Name
}
Register-ArgumentCompleter -CommandName Add-PWSHModule -ParameterName Repository -ScriptBlock $scriptBlock
 
Export-ModuleMember -Function Add-PWSHModule
#endregion
 
#region Install-PWSHModule.ps1
######## Function 2 of 6 ##################
# Function:         Install-PWSHModule
# Module:           PWSHModule
# ModuleVersion:    0.1.2
# Author:           Pierre Smit
# Company:          HTPCZA Tech
# CreatedOn:        2022/07/12 07:38:48
# ModifiedOn:       2022/07/13 02:04:49
# Synopsis:         Install modules from a config file
#############################################
 
<#
.SYNOPSIS
Install modules from a config file

.DESCRIPTION
Install modules from a config file

.PARAMETER Export
Export the result to a report file. (Excel or html). Or select Host to display the object on screen.

.PARAMETER ReportPath
Where to save the report.

.EXAMPLE
Install-PWSHModule -Export HTML -ReportPath C:\temp

#>
Function Install-PWSHModule {
	[Cmdletbinding(DefaultParameterSetName = 'Set1', HelpURI = 'https://smitpi.github.io/PWSHModule/Install-PWSHModule')]
	[OutputType([System.Object[]])]
	PARAM(
		[string]$GitHubUserID, 
		[string]$GitHubToken,
		[string]$ListName,
		[ValidateSet('AllUsers', 'CurrentUser')]
		[string]$Scope
	)

	if ($scope -like 'AllUsers') {
	 $IsAdmin = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
		if (-not($IsAdmin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) { Throw 'Must be running an elevated prompt.' }
	}

	try {
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
		$Content = (Invoke-WebRequest -Uri ($PRGist.files.$($ListName)).raw_url -Headers $headers).content | ConvertFrom-Json -ErrorAction Stop
	} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
	if ([string]::IsNullOrEmpty($Content.CreateDate) -or [string]::IsNullOrEmpty($Content.Modules)) {Throw 'Invalid Config File'}

	foreach ($module in $Content.Modules) {
		if ($module.Version -like 'Latest') {
			$mod = Get-Module -Name $module.Name
			if (-not($mod)) {$mod = Get-Module -Name $module.name -ListAvailable}
			if (-not($mod)) { 
				Write-Host '[Installing]' -NoNewline -ForegroundColor Yellow ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name)" -ForegroundColor Green
				Install-Module -Name $module.Name -Repository $module.Repository -Scope $Scope -Force -AllowClobber
			} else {
				Write-Host '[Installed]' -NoNewline -ForegroundColor Yellow ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name) " -ForegroundColor Green -NoNewline ; Write-Host "$($mod.Path)" -ForegroundColor DarkRed
				$OnlineMod = Find-Module -Name $module.name -Repository $module.Repository
				[version]$Onlineversion = $OnlineMod.version 
				[version]$Localversion = ($mod | Sort-Object -Property Version -Descending)[0].Version
				if ($Localversion -lt $Onlineversion) {
					Write-Host "`t[Upgrading]" -NoNewline -ForegroundColor Yellow ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name)" -ForegroundColor Green ; Write-Host " v$($OnlineMod.version)" -ForegroundColor DarkRed
					try {
						Update-Module -Name $module.Name -Force -ErrorAction Stop
					} catch {
						try {
							Install-Module -Name $module.name -Scope $Scope -Repository $module.Repository -AllowClobber -Force
						} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
					}
				}
			}
		} else {
			$mod = Get-Module -Name $module.Name
			if (-not($mod)) {$mod = Get-Module -Name $module.name -ListAvailable}
			if ((-not($mod)) -or $mod.Version -lt $module.Version) {
				Write-Host '[Installing]' -NoNewline -ForegroundColor Yellow ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name)" -ForegroundColor Green
				Install-Module -Name $module.Name -Repository $module.Repository -RequiredVersion $module.Version -Scope $Scope -Force -AllowClobber
			} else {
				Write-Host '[Installed]' -NoNewline -ForegroundColor Yellow ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name) " -ForegroundColor Green -NoNewline ; Write-Host "$($mod.Path)" -ForegroundColor DarkRed
			}
		}
	}
} #end Function
 
Export-ModuleMember -Function Install-PWSHModule
#endregion
 
#region New-PWSHModuleList.ps1
######## Function 3 of 6 ##################
# Function:         New-PWSHModuleList
# Module:           PWSHModule
# ModuleVersion:    0.1.2
# Author:           Pierre Smit
# Company:          HTPCZA Tech
# CreatedOn:        2022/07/09 15:22:20
# ModifiedOn:       2022/07/13 05:42:54
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

	$NewConfig = [PSCustomObject]@{
		CreateDate  = (Get-Date -Format u)
		Description = $Description
		Author      = "$($env:USERNAME.ToLower())@$($env:USERDNSDOMAIN.ToLower())"
		Modified    = 'Unknown'
		Modules     = [PSCustomObject]@{
			Name        = 'PWSHModule'
			Version     = 'Latest'
			Description = 'Uses a GitHub Gist File to install and maintain a list of PowerShell Modules'
			Repository  = 'PSGallery'
			Projecturi  = 'https://github.com/smitpi/PWSHModule'
		}
 } | ConvertTo-Json

	$ConfigFile = Join-Path $env:TEMP -ChildPath "$($ListName).json"
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
} #end Function
 
Export-ModuleMember -Function New-PWSHModuleList
#endregion
 
#region Remove-PWSHModule.ps1
######## Function 4 of 6 ##################
# Function:         Remove-PWSHModule
# Module:           PWSHModule
# ModuleVersion:    0.1.2
# Author:           Pierre Smit
# Company:          HTPCZA Tech
# CreatedOn:        2022/07/09 15:58:24
# ModifiedOn:       2022/07/13 02:07:02
# Synopsis:         Remove a module to the config file
#############################################
 
<#
.SYNOPSIS
Remove a module to the config file

.DESCRIPTION
Remove a module to the config file

.PARAMETER Export
Export the result to a report file. (Excel or html). Or select Host to display the object on screen.

.PARAMETER ReportPath
Where to save the report.

.EXAMPLE
Remove-PWSHModule -Export HTML -ReportPath C:\temp

#>
Function Remove-PWSHModule {
	[Cmdletbinding(DefaultParameterSetName = 'Set1', HelpURI = 'https://smitpi.github.io/PWSHModule/Remove-PWSHModule')]
	PARAM(
		[string]$GitHubUserID, 
		[string]$GitHubToken,
		[string]$ListName,
		[String]$ModuleName
	)

	try {
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
		$Content = (Invoke-WebRequest -Uri ($PRGist.files.$($ListName)).raw_url -Headers $headers).content | ConvertFrom-Json -ErrorAction Stop
	} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
	if ([string]::IsNullOrEmpty($Content.CreateDate) -or [string]::IsNullOrEmpty($Content.Modules)) {Throw 'Invalid Config File'}

	$Modremove = $Content.Modules | Where-Object {$_.Name -like $ModuleName}
	if ([string]::IsNullOrEmpty($Modremove) -or ($Modremove.name.count -gt 1)) {
		throw 'Module not found'
	} else {
		[System.Collections.ArrayList]$ModuleObject = @()		
		$Content.Modules | ForEach-Object {[void]$ModuleObject.Add($_)}
		$ModuleObject.Remove($Modremove)
		Write-Host '[Removed]' -NoNewline -ForegroundColor Yellow; Write-Host " $($Modremove.Name)" -NoNewline -ForegroundColor Cyan; Write-Host " to $($ListName)" -ForegroundColor Green
		$Content.Modules = $ModuleObject | Sort-Object -Property name
		$Content.Modified = "[$(Get-Date -Format u)] -- $($env:USERNAME.ToLower())@$($env:USERDNSDOMAIN.ToLower())"

		try {
			$Body = @{}
			$files = @{}
			$Files["$($PRGist.files.$($ListName).Filename)"] = @{content = ( $Content | ConvertTo-Json | Out-String ) }
			$Body.files = $Files
			$Uri = 'https://api.github.com/gists/{0}' -f $PRGist.id
			$json = ConvertTo-Json -InputObject $Body
			$json = [System.Text.Encoding]::UTF8.GetBytes($json)
			$null = Invoke-WebRequest -Headers $headers -Uri $Uri -Method Patch -Body $json -ErrorAction Stop
			Write-Host '[Uploaded]' -NoNewline -ForegroundColor Yellow; Write-Host " $($ListName).json" -NoNewline -ForegroundColor Cyan; Write-Host ' to Github Gist' -ForegroundColor Green
		} catch {throw "Can't connect to gist:`n $($_.Exception.Message)"}
	}

} #end Function
 
Export-ModuleMember -Function Remove-PWSHModule
#endregion
 
#region Show-PWSHModule.ps1
######## Function 5 of 6 ##################
# Function:         Show-PWSHModule
# Module:           PWSHModule
# ModuleVersion:    0.1.2
# Author:           Pierre Smit
# Company:          HTPCZA Tech
# CreatedOn:        2022/07/09 15:57:20
# ModifiedOn:       2022/07/13 05:51:26
# Synopsis:         List the content of a config file
#############################################
 
<#
.SYNOPSIS
List the content of a config file

.DESCRIPTION
List the content of a config file

.PARAMETER Export
Export the result to a report file. (Excel or html). Or select Host to display the object on screen.

.PARAMETER ReportPath
Where to save the report.

.EXAMPLE
Show-PWSHModule -Export HTML -ReportPath C:\temp

#>
Function Show-PWSHModule {
	[Cmdletbinding(HelpURI = 'https://smitpi.github.io/PWSHModule/Show-PWSHModule')]
	PARAM(
		[Parameter(Mandatory = $true)]
		[string]$GitHubUserID, 
		[string]$GitHubToken,
		[string]$Listname,
		[switch]$AsTable,
		[switch]$ShowProjectURI
	)

	try {
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
		$Content = (Invoke-WebRequest -Uri ($PRGist.files.$($Listname)).raw_url -Headers $headers).content | ConvertFrom-Json -ErrorAction Stop
	} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
	if ([string]::IsNullOrEmpty($Content.CreateDate) -or [string]::IsNullOrEmpty($Content.Modules)) {Throw 'Invalid Config File'}

	$index = 0
	[System.Collections.ArrayList]$ModuleObject = @()		
	$Content.Modules | ForEach-Object {				
		[void]$ModuleObject.Add([PSCustomObject]@{
				Index       = $index
				Name        = $_.Name
				Version     = $_.version
				Description = $_.Description
				Repository  = $_.$Repository
				Projecturi  = $_.projecturi
			})
		$index++
	}

	if ($AsTable) {$ModuleObject | Format-Table -AutoSize}
	else {$ModuleObject}

	if ($ShowProjectURI) {
		Write-Output ' '
		[int]$IndexURI = Read-Host 'Module Index Number'
		if ($Content.Modules[$IndexURI].projecturi -notlike 'Unknown') {
			Start-Process "$($Content.Modules[$IndexURI].projecturi)"
		} else { Write-Warning 'Unknown ProjectURI'}
	}
} #end Function
 
Export-ModuleMember -Function Show-PWSHModule
#endregion
 
#region Show-PWSHModuleList.ps1
######## Function 6 of 6 ##################
# Function:         Show-PWSHModuleList
# Module:           PWSHModule
# ModuleVersion:    0.1.2
# Author:           Pierre Smit
# Company:          HTPCZA Tech
# CreatedOn:        2022/07/13 01:15:39
# ModifiedOn:       2022/07/13 05:50:43
# Synopsis:         List all the GitHub Gist Lists.
#############################################
 
<#
.SYNOPSIS
Shows a list of all the Config files in GitHub

.DESCRIPTION
Shows a list of all the Config files in GitHub

.PARAMETER Export
Export the result to a report file. (Excel or html). Or select Host to display the object on screen.

.PARAMETER ReportPath
Where to save the report.

.EXAMPLE
Show-PWSHModuleList -Export HTML -ReportPath C:\temp

#>
<#
.SYNOPSIS
List all the GitHub Gist Lists.

.DESCRIPTION
List all the GitHub Gist Lists.

.PARAMETER GitHubUserID
The GitHub User ID.

.PARAMETER GitHubToken
GitHub Token with access to the Users' Gist.

.EXAMPLE
Show-PWSHModuleList -GitHubUserID smitpi -GitHubToken $GitHubToken 

#>
Function Show-PWSHModuleList {
	[Cmdletbinding(HelpURI = 'https://smitpi.github.io/PWSHModule/Show-PWSHModuleList')]
	PARAM(
		[Parameter(Mandatory = $true)]
		[string]$GitHubUserID, 
		[Parameter(Mandatory = $true)]
		[string]$GitHubToken
	)

	
	try {
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
	$PRGist.files | Get-Member -MemberType NoteProperty | ForEach-Object {
		$Content = (Invoke-WebRequest -Uri ($PRGist.files.$($_.name)).raw_url -Headers $headers).content | ConvertFrom-Json -ErrorAction Stop
		if ($Content.modified -notlike 'Unknown') {
			$modifiedDate = [datetime](($Content.modified.split(' -- ')[0]).replace('[', '')).replace(']', '')
			$modifiedUser = $Content.modified.split(' -- ')[1]
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

} #end Function
 
Export-ModuleMember -Function Show-PWSHModuleList
#endregion
 
#endregion
 
