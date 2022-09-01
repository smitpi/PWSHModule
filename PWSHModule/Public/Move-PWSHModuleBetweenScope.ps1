
<#PSScriptInfo

.VERSION 0.1.0

.GUID 7e0a3726-3385-4da4-bd3d-6e7c967ad135

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
Created [20/08/2022_12:38] Initial Script Creating

.PRIVATEDATA

#>

<# 

.DESCRIPTION 
 Will move modules between scopes (CurrentUser and AllUsers) 

#> 


<#
.SYNOPSIS
Moves modules between scopes (CurrentUser and AllUsers).

.DESCRIPTION
Moves modules between scopes (CurrentUser and AllUsers).

.PARAMETER SourceScope
From where the modules will be copied.

.PARAMETER DestinationScope
To there the modules will be copied.

.PARAMETER ModuleName
Name of the modules to move. You can select multiple names or you can use * to select all.

.PARAMETER PSRepository
The repository will be used to install the module at the destination.

.EXAMPLE
Move-PWSHModuleBetweenScope -SourceScope D:\Documents\PowerShell\Modules -DestinationScope C:\Program Files\PowerShell\Modules -ModuleName PWSHMOdule -PSRepository psgallery

#>
Function Move-PWSHModuleBetweenScope {
	[Cmdletbinding(HelpURI = 'https://smitpi.github.io/PWSHModule/Move-PWSHModuleBetweenScope')]
	[OutputType([System.Object[]])]
	PARAM(
		[Parameter(Mandatory = $true)]
		[ValidateScript( { $IsAdmin = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
				if ($IsAdmin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { $True }
				else { Throw 'Must be running an elevated prompt.' } })]
		[System.IO.DirectoryInfo]$SourceScope,

		[Parameter(Mandatory = $true)]
		[System.IO.DirectoryInfo]$DestinationScope,

		[Parameter(ValueFromPipeline, Mandatory)]
		[Alias('Name')]
		[string[]]$ModuleName,

		[string]$PSRepository = 'PSGallery'
	)

	if ($ModuleName -like 'All') {$ModuleName = (Get-ChildItem -Path $($SourceScope) -Directory).Name }

	foreach ($mod in $ModuleName) {
		Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Checking for installed module $($mod)"
		try {
			$MoveMod = Get-Module -Name $mod -ListAvailable -ErrorAction Stop | Where-Object {$_.path -like "$($SourceScope)*"} | Sort-Object -Property Version -Descending | Select-Object -First 1
		} catch {Write-Warning "Did not find $($ModuleName) in $($SourceScope)"}
		try {
			Write-Verbose "[$(Get-Date -Format HH:mm:ss) Saving] Module $($MoveMod.name)"
			Write-Host '[Moving] ' -NoNewline -ForegroundColor Yellow ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($MoveMod.Name)($($MoveMod.Version)) " -ForegroundColor Green -NoNewline ; Write-Host "$($DestinationScope)" -ForegroundColor DarkRed			
			Save-Module -Name $MoveMod.Name -RequiredVersion $MoveMod.Version -Repository $PSRepository -Force -AllowPrerelease -AcceptLicense -Path (Get-Item $DestinationScope).FullName -ErrorAction Stop
			Write-Verbose "[$(Get-Date -Format HH:mm:ss) Uninstalling] Module $($MoveMod.name)"
			Write-Host "`t[Deleteing] " -NoNewline -ForegroundColor Yellow ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($MoveMod.Name)($($MoveMod.Version)) " -ForegroundColor Green -NoNewline ; Write-Host "$($SourceScope)" -ForegroundColor DarkRed			
			if (Test-Path (Join-Path $DestinationScope -ChildPath "$($MoveMod.Name)\$($MoveMod.Version)")) {
				Join-Path -Path (Get-Item $MoveMod.Path) -ChildPath '..\..' -Resolve -ErrorAction Stop | Remove-Item -Recurse -Force
			} else {Write-Warning 'Move failed, leaving source directory.'}
		} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
		Write-Verbose "[$(Get-Date -Format HH:mm:ss) Complete"
	}
} #end Function
$scriptblock = {
	param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
	$env:PSModulePath.Split(';') | ForEach-Object {"""$($_)"""}
}
Register-ArgumentCompleter -CommandName Move-PWSHModuleBetweenScope -ParameterName SourceScope -ScriptBlock $scriptBlock
Register-ArgumentCompleter -CommandName Move-PWSHModuleBetweenScope -ParameterName DestinationScope -ScriptBlock $scriptBlock

$scriptblock2 = {
	param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
	$ModList = @()
	$ModList += 'All'
	$modlist += ([IO.Path]::Combine("$([Environment]::GetFolderPath('MyDocuments'))", 'WindowsPowerShell', 'Modules') | Get-ChildItem -Directory).Name
	$modlist += ([IO.Path]::Combine("$([Environment]::GetFolderPath('MyDocuments'))", 'PowerShell', 'Modules') | Get-ChildItem -Directory).Name
	$modlist += ([IO.Path]::Combine("$($env:ProgramFiles)", 'WindowsPowerShell', 'Modules') | Get-ChildItem -Directory).Name
	$modlist += ([IO.Path]::Combine("$($env:ProgramFiles)", 'PowerShell', 'Modules') | Get-ChildItem -Directory).Name
	$ModList | Select-Object -Unique
}
Register-ArgumentCompleter -CommandName Move-PWSHModuleBetweenScope -ParameterName ModuleName -ScriptBlock $scriptBlock2

$scriptblock3 = {
	param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
	Get-PSRepository | ForEach-Object {$_.name}
}
Register-ArgumentCompleter -CommandName Move-PWSHModuleBetweenScope -ParameterName PSRepository -ScriptBlock $scriptBlock3