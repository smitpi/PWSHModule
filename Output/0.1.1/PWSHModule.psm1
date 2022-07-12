#region Private Functions
#region DisplayOutput.ps1
########### Private Function ###############
# Source:           DisplayOutput.ps1
# Module:           PWSHModule
# ModuleVersion:    0.1.1
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
######## Function 1 of 5 ##################
# Function:         Add-PWSHModule
# Module:           PWSHModule
# ModuleVersion:    0.1.1
# Author:           Pierre Smit
# Company:          HTPCZA Tech
# CreatedOn:        2022/07/09 15:57:31
# ModifiedOn:       2022/07/12 07:37:35
# Synopsis:         Add a module to the config file
#############################################
 
<#
.SYNOPSIS
Add a module to the config file

.DESCRIPTION
Add a module to the config file

.PARAMETER Export
Export the result to a report file. (Excel or html). Or select Host to display the object on screen.

.PARAMETER ReportPath
Where to save the report.

.EXAMPLE
Add-PWSHModule -Export HTML -ReportPath C:\temp

#>
Function Add-PWSHModule {
	[Cmdletbinding(DefaultParameterSetName = 'Set1', HelpURI = 'https://smitpi.github.io/PWSHModule/Add-PWSHModule')]
	PARAM(
		[Parameter(Mandatory = $true)]
		[ValidateScript( { (Test-Path $_) -and ((Get-Item $_).Extension -eq '.json') })]
		[System.IO.FileInfo]$Path,
		[Parameter(Mandatory = $true)]
		[string]$ModuleName,
		[Parameter(Mandatory = $true)]
		[String]$Repository,
		[switch]$RequiredVersion
	)

	try {
		$Content = (Get-Content $Path -ErrorAction Stop) | ConvertFrom-Json -ErrorAction Stop
	} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
	if ([string]::IsNullOrEmpty($Content.Date) -or [string]::IsNullOrEmpty($Content.Modules)) {Throw 'Invalid Config File'}

	[System.Collections.ArrayList]$ModuleObject = @()		
	$Content.Modules | ForEach-Object {[void]$ModuleObject.Add($_)}
	$index = 0
	$FilterMod = Find-Module -Filter $ModuleName -Repository $Repository | ForEach-Object {
		[PSCustomObject]@{
			Index       = $index
			Name        = $_.Name
			Version     = $_.version
			Description = $_.Description
			ProjectURI  = $_.ProjectUri.AbsoluteUri
		}
		$index++
	}

	if ($filtermod.count -gt 1) {
		$FilterMod | Select-Object Index, Name, Description | Format-Table -AutoSize -Wrap
		$num = Read-Host 'Index Number '
		$ModuleToAdd = $filtermod[$num]
	} elseif ($filtermod.Count -eq 1) {
		$ModuleToAdd = $filtermod
	} else {throw 'Module not found'}

	if ($RequiredVersion) {
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
	} else {$VersionToAdd = 'Latest'}

	[void]$ModuleObject.Add([PSCustomObject]@{
			Name        = $ModuleToAdd.Name
			Repository  = $Repository457
			Description = $ModuleToAdd.Description
			Version     = $VersionToAdd
			Projecturi  = $ModuleToAdd.ProjectUri
		})

	$Content.Modules = $ModuleObject | Sort-Object -Property name
	$Content | ConvertTo-Json | Set-Content -Path $Path
} #end Function
 
Export-ModuleMember -Function Add-PWSHModule
#endregion
 
#region Install-PWSHModule.ps1
######## Function 2 of 5 ##################
# Function:         Install-PWSHModule
# Module:           PWSHModule
# ModuleVersion:    0.1.1
# Author:           Pierre Smit
# Company:          HTPCZA Tech
# CreatedOn:        2022/07/12 07:38:48
# ModifiedOn:       2022/07/12 12:16:59
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
		[Parameter(Mandatory = $true)]
		[ValidateScript( { (Test-Path $_) -and ((Get-Item $_).Extension -eq '.json') })]
		[System.IO.FileInfo]$Path,
		[ValidateSet('AllUsers', 'CurrentUser')]
		[string]$Scope
	)

	if ($scope -like 'AllUsers') {
	 $IsAdmin = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
		if (-not($IsAdmin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) { Throw 'Must be running an elevated prompt.' }
	}

	try {
		$Content = (Get-Content $Path -ErrorAction Stop) | ConvertFrom-Json -ErrorAction Stop
	} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
	if ([string]::IsNullOrEmpty($Content.Date) -or [string]::IsNullOrEmpty($Content.Modules)) {Throw 'Invalid Config File'}

	foreach ($module in $Content.Modules) {
		if ($module.Version -like 'Latest') {
			$mod = Get-Module -Name $module.Name
			if (-not($mod)) {$mod = Get-Module -Name $module.name -ListAvailable}
			if (-not($mod)) { 
				Write-Host '[Installing]' -NoNewline -ForegroundColor Yellow ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name)" -ForegroundColor Green
				Install-Module -Name $module.Name -Repository $module.Repository -Scope $Scope -Force -AllowClobber
			} else {
				Write-Host '[Installed]' -NoNewline -ForegroundColor Yellow ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name) " -ForegroundColor Green -NoNewline ; Write-Host "$($mod.Path)" -ForegroundColor DarkRed
				[version]$Onlineversion = (Find-Module -Name $module.name -Repository $module.Repository).version
				[version]$Localversion = ($mod | Sort-Object -Property Version -Descending)[0].Version
				if ($Localversion -lt $Onlineversion) {
					Write-Host "`t[Upgrading]" -NoNewline -ForegroundColor Yellow ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name)" -ForegroundColor Green
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
 
#region New-PWSHModuleConfigFile.ps1
######## Function 3 of 5 ##################
# Function:         New-PWSHModuleConfigFile
# Module:           PWSHModule
# ModuleVersion:    0.1.1
# Author:           Pierre Smit
# Company:          HTPCZA Tech
# CreatedOn:        2022/07/09 15:22:20
# ModifiedOn:       2022/07/09 18:32:52
# Synopsis:         Create a new config file.
#############################################
 
<#
.SYNOPSIS
Create a new config file.

.DESCRIPTION
Create a new config file.

.PARAMETER Export
Export the result to a report file. (Excel or html). Or select Host to display the object on screen.

.PARAMETER ReportPath
Where to save the report.

.EXAMPLE
New-PWSHModuleConfigFile -Export HTML -ReportPath C:\temp

#>
<#
.SYNOPSIS
Create a new config file.

.DESCRIPTION
Create a new json config file in the path specified.

.PARAMETER Path
Path where the config file will be created. If the path doesn't exist, it will be created.

.EXAMPLE
New-PWSHModuleConfigFile -Path C:\temp

#>
Function New-PWSHModuleConfigFile {
	[Cmdletbinding( HelpURI = 'https://smitpi.github.io/PWSHModule/New-PWSHModuleConfigFile')]
	[OutputType([System.Object[]])]
	PARAM(
		[Parameter(Mandatory = $true)]
		[ValidateScript( { if (Test-Path $_) { $true }
				else { New-Item -Path $_ -ItemType Directory -Force | Out-Null; $true }
			})]
		[System.IO.DirectoryInfo]$Path,
		[string]$Description = 'Created by PWSHModule PowerShell Module.'
	)
	$NewConfig = [PSCustomObject]@{
		Date        = (Get-Date -Format u)
		Description = $Description
		Author      = "$($env:USERNAME.ToLower())@$($env:USERDNSDOMAIN.ToLower())"
		Modules     = [PSCustomObject]@{
			Name        = 'PWSHModule'
			Repository  = 'PSGallery'
			Description = 'Uses a Config file to install and maintain a list of PowerShell Modules'
			Version     = 'Latest'
			Projecturi  = "https://github.com/smitpi/PWSHModule"
		}
 } | ConvertTo-Json

	$ConfigFile = Join-Path $Path -ChildPath 'PWSHModules.json'
	if (Test-Path $ConfigFile) {
		Write-Warning "Config File exists, Renaming file to PWSHModules-$(Get-Date -Format yyyyMMdd_HHmm).json"	
		try {
			Rename-Item $ConfigFile -NewName "PWSHModules-$(Get-Date -Format yyyyMMdd_HHmm).json" -Force -ErrorAction Stop | Out-Null
		} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message);exit"}
	}
	Write-Color '[Creating]', ' New Config file:', " $($ConfigFile)" -Color Yellow, Green, Cyan
	try {
		$NewConfig | Set-Content -Path $ConfigFile -Encoding utf8 -ErrorAction Stop
	} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
} #end Function
 
Export-ModuleMember -Function New-PWSHModuleConfigFile
#endregion
 
#region Remove-PWSHModule.ps1
######## Function 4 of 5 ##################
# Function:         Remove-PWSHModule
# Module:           PWSHModule
# ModuleVersion:    0.1.1
# Author:           Pierre Smit
# Company:          HTPCZA Tech
# CreatedOn:        2022/07/09 15:58:24
# ModifiedOn:       2022/07/12 07:37:01
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
		[Parameter(Mandatory = $true)]
		[ValidateScript( { (Test-Path $_) -and ((Get-Item $_).Extension -eq '.json') })]
		[System.IO.FileInfo]$Path,
		[String]$ModuleName
	)

	try {
		$Content = (Get-Content $Path -ErrorAction Stop) | ConvertFrom-Json -ErrorAction Stop
	} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
	if ([string]::IsNullOrEmpty($Content.Date) -or [string]::IsNullOrEmpty($Content.Modules)) {Throw 'Invalid Config File'}

	$Modremove = $Content.Modules | Where-Object {$_.Name -like $ModuleName}
	if ($Modremove.count -ne 1) {
		throw 'Module not found'
	} else {
		[System.Collections.ArrayList]$ModuleObject = @()		
		$Content.Modules | ForEach-Object {[void]$ModuleObject.Add($_)}
		$ModuleObject.Remove($Modremove)
		$Content.Modules = $ModuleObject
		$Content | ConvertTo-Json | Set-Content -Path $Path	
	}
} #end Function
 
Export-ModuleMember -Function Remove-PWSHModule
#endregion
 
#region Show-PWSHModule.ps1
######## Function 5 of 5 ##################
# Function:         Show-PWSHModule
# Module:           PWSHModule
# ModuleVersion:    0.1.1
# Author:           Pierre Smit
# Company:          HTPCZA Tech
# CreatedOn:        2022/07/09 15:57:20
# ModifiedOn:       2022/07/12 07:37:13
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
		[ValidateScript( { (Test-Path $_) -and ((Get-Item $_).Extension -eq '.json') })]
		[System.IO.FileInfo]$Path,
		[switch]$AsTable,
		[switch]$ShowProjectURI
	)

	try {
		$Content = (Get-Content $Path -ErrorAction Stop) | ConvertFrom-Json -ErrorAction Stop
	} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
	if ([string]::IsNullOrEmpty($Content.Date) -or [string]::IsNullOrEmpty($Content.Modules)) {Throw 'Invalid Config File'}

	if ($AsTable) {$Content.Modules | Format-Table -AutoSize}
	else {$Content.Modules}

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
 
#endregion
 
