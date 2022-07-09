
<#PSScriptInfo

.VERSION 0.1.0

.GUID f2314cf6-8ba1-49f0-b09d-396d72749014

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
Created [09/07/2022_15:22] Initial Script Creating

.PRIVATEDATA

#>

#Requires -Module PSWriteColor

<# 

.DESCRIPTION 
 Create a new config file. 

#> 


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
		[System.IO.DirectoryInfo]$Path
	)
	$NewConfig = [PSCustomObject]@{
		Name       = 'PWSHModule'
		Repository = 'PSGallery'
		Version    = 'Latest'
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
