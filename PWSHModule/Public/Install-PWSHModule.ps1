
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
