
<#PSScriptInfo

.VERSION 0.1.0

.GUID c14e94e9-1634-4680-acb2-206c4649338b

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
Created [31/07/2022_11:51] Initial Script Creating

.PRIVATEDATA

#>



<# 

.DESCRIPTION 
 Creates PSDefaultParameterValues in the users profile files 

#> 



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

.PARAMETER RemoveConfig
Removes the config from your profile.

.EXAMPLE
Add-PWSHModuleDefaultsToProfile -GitHubUserID smitpi -PublicGist -Scope AllUsers

#>
Function Add-PWSHModuleDefaultsToProfile {
	[Cmdletbinding(DefaultParameterSetName = 'Public', HelpURI = 'https://smitpi.github.io/PWSHModule/Add-PWSHModuleDefaultsToProfile')]
	[OutputType([System.Object[]])]
	PARAM(
		[Parameter(Mandatory)]
		[string]$GitHubUserID, 
		[Parameter(ParameterSetName = 'Public')]
		[switch]$PublicGist,
		[Parameter(ParameterSetName = 'Private')]
		[string]$GitHubToken,
		[ValidateSet('AllUsers', 'CurrentUser')]
		[string]$Scope,
		[switch]$RemoveConfig
	)

	## TODO Add remove config from profile.

	if ($PublicGist) {
		$Script:PSDefaultParameterValues['*PWSHModule*:GitHubUserID'] = "$($GitHubUserID)"
		$Script:PSDefaultParameterValues['*PWSHModule*:PublicGist'] = $true
		$Script:PSDefaultParameterValues['*PWSHModule*:Scope'] = "$($Scope)"

		$ToAppend = @"

#region PWSHModule Defaults
`$PSDefaultParameterValues['*PWSHModule*:GitHubUserID'] = "$($GitHubUserID)"
`$PSDefaultParameterValues['*PWSHModule*:PublicGist'] = `$true
`$PSDefaultParameterValues['*PWSHModule*:Scope'] = "$($Scope)"
#endregion PWSHModule
"@
	} else {
		$Script:PSDefaultParameterValues['*PWSHModule*:GitHubUserID'] = "$($GitHubUserID)"
		$Script:PSDefaultParameterValues['*PWSHModule*:GitHubToken'] = "$($GitHubToken)"
		$Script:PSDefaultParameterValues['*PWSHModule*:Scope'] = "$($Scope)"
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
		if (-not($RemoveConfig)) {Add-Content -Value $ToAppend -Path $file.FullName -Force -Encoding utf8}
		Write-Host '[Updated]' -NoNewline -ForegroundColor Yellow; Write-Host ' Profile File:' -NoNewline -ForegroundColor Cyan; Write-Host " $($file.FullName)" -ForegroundColor Green
	}

} #end Function
