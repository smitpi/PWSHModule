
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

.PARAMETER Repository
The repository will be used to install the module at the destination.

.EXAMPLE
Move-PWSHModuleBetweenScope -SourceScope D:\Documents\PowerShell\Modules -DestinationScope C:\Program Files\PowerShell\Modules -ModuleName PWSHMOdule -Repository psgallery

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

		[Parameter(ValueFromPipeline)]
		[Alias('Name')]
		[string[]]$ModuleName = 'All',

		[string]$Repository = 'PSGallery'
	)

	if ($ModuleName -like 'All') {$ModuleName = (Get-ChildItem -Path $($SourceScope) -Directory).Name }

	foreach ($mod in $ModuleName) {
		$CheckModInFolder = Get-ChildItem -Path (Join-Path $SourceScope -ChildPath "$($mod)\*\$($mod).psm1") | Sort-Object -Property directory -Descending | Select-Object -First 1
		if ([string]::IsNullOrEmpty($CheckModInFolder)) {
			Write-Warning "$($mod) is not a valid module in folder: $($SourceScope)"
		} else {
			Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Checking for installed module $($mod)"
			try {
				$CheckModule = Get-Module -FullyQualifiedName $CheckModInFolder.FullName -ListAvailable
				if ($CheckModule.Version.ToString() -eq '0.0') {[version]$ModuleVersion = (Import-PowerShellDataFile $CheckModInFolder.FullName.Replace('psm1', 'psd1')).ModuleVersion}
				else {[version]$ModuleVersion = $CheckModule.Version}
				Remove-Module $mod -Force -ErrorAction SilentlyContinue
			} catch {Write-Warning "Did not find $($ModuleName) in $($SourceScope)"}
			Write-Host '[Moving] ' -NoNewline -ForegroundColor Yellow ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($CheckModule.Name)($($CheckModule.Version)) " -ForegroundColor Green -NoNewline ; Write-Host "$($DestinationScope)" -ForegroundColor DarkRed			
			try {
				Write-Verbose "[$(Get-Date -Format HH:mm:ss) ADDING] to archive"
				    (Get-Item $CheckModule.Path).directory.Parent.FullName | Compress-Archive -DestinationPath (Join-Path -Path $SourceScope -ChildPath 'PWSHModule_Move.zip') -Update -ErrorAction Stop
				Write-Verbose "[$(Get-Date -Format HH:mm:ss) Deleteing folder"
    				(Get-Item $CheckModule.Path).directory.Parent.FullName | Remove-Item -Recurse -Force -ErrorAction Stop
				Write-Verbose "[$(Get-Date -Format HH:mm:ss) Saving] Module $($MoveMod.name)"
					Save-Module -Name $CheckModule.Name -RequiredVersion $ModuleVersion -Repository $Repository -Force -AcceptLicense -Path (Get-Item $DestinationScope).FullName -ErrorAction Stop
			} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
			Write-Verbose "[$(Get-Date -Format HH:mm:ss) Complete"
		}
	}
} #end Function
$scriptblock = {
	param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
	$env:PSModulePath.Split(';') | ForEach-Object {"""$($_)"""}
}
Register-ArgumentCompleter -CommandName Move-PWSHModuleBetweenScope -ParameterName SourceScope -ScriptBlock $scriptBlock
Register-ArgumentCompleter -CommandName Move-PWSHModuleBetweenScope -ParameterName DestinationScope -ScriptBlock $scriptBlock

$scriptblock3 = {
	param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
	(Get-Repository).name | Where-Object {$_ -like "*$wordToComplete*"}
}
Register-ArgumentCompleter -CommandName Move-PWSHModuleBetweenScope -ParameterName Repository -ScriptBlock $scriptBlock3