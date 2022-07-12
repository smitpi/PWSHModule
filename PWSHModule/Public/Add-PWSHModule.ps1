
<#PSScriptInfo

.VERSION 0.1.0

.GUID 956d0d59-2167-433c-ab10-31c260546997

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
#Requires -Module PSWriteColor
<# 

.DESCRIPTION 
 Add a module to the config file 

#> 


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
	[OutputType([System.Object[]])]
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
