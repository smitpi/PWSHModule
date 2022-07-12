
<#PSScriptInfo

.VERSION 0.1.0

.GUID 8f6e75a2-4b86-4472-90a3-688fa4ee7cda

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
Created [09/07/2022_15:57] Initial Script Creating

.PRIVATEDATA

#>

#Requires -Module PSWriteColor

<# 

.DESCRIPTION 
 List the content of a config file 

#> 


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
	[OutputType([System.Object[]])]
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
