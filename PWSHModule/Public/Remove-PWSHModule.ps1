
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
