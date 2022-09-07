
<#PSScriptInfo

.VERSION 0.1.0

.GUID 8131444f-5033-4051-a5dc-c1b222c7a4c0

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
Created [07/09/2022_16:36] Initial Script

.PRIVATEDATA

#>

<# 

.DESCRIPTION 
 Save the Gist file to a local file 

#> 


<#
.SYNOPSIS
Save the Gist file to a local file

.DESCRIPTION
Save the Gist file to a local file

.PARAMETER ListName
Name of the list.

.PARAMETER GitHubUserID
User with access to the gist.

.PARAMETER PublicGist
Select if the list is hosted publicly.

.PARAMETER GitHubToken
The token for that gist.

.PARAMETER Path
Directory where files will be saved.

.EXAMPLE
Save-PWSHModuleList -ListName Base,twee -Path C:\temp

#>
Function Save-PWSHModuleList {
	[Cmdletbinding(DefaultParameterSetName = 'Set1', HelpURI = 'https://smitpi.github.io/PWSHModule/Save-PWSHModuleList')]
	PARAM(
		[Parameter(Mandatory)]
		[string[]]$ListName,
		[Parameter(Mandatory)]
		[System.IO.DirectoryInfo]$Path,
		[Parameter(Mandatory)]
		[string]$GitHubUserID, 
		[Parameter(ParameterSetName = 'Public')]
		[switch]$PublicGist,
		[Parameter(ParameterSetName = 'Private')]
		[string]$GitHubToken
	)

	try {
		Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Connect to gist"
		$headers = @{}
		$auth = '{0}:{1}' -f $GitHubUserID, $GitHubToken
		$bytes = [System.Text.Encoding]::ASCII.GetBytes($auth)
		$base64 = [System.Convert]::ToBase64String($bytes)
		$headers.Authorization = 'Basic {0}' -f $base64

		$url = 'https://api.github.com/users/{0}/gists' -f $GitHubUserID
		$AllGist = Invoke-RestMethod -Uri $url -Method Get -Headers $headers -ErrorAction Stop
		$PRGist = $AllGist | Select-Object | Where-Object { $_.description -like 'PWSHModule-ConfigFile' }
	} catch {throw "Can't connect to gist:`n $($_.Exception.Message)"}

	foreach ($List in $ListName) {
		try {
			Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Checking Config File"
			$Content = (Invoke-WebRequest -Uri ($PRGist.files.$($List)).raw_url -Headers $headers).content | ConvertFrom-Json -ErrorAction Stop
		} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
		if ([string]::IsNullOrEmpty($Content.CreateDate) -or [string]::IsNullOrEmpty($Content.Modules)) {Write-Error 'Invalid Config File'}
		$Content | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $Path -ChildPath "$($list).json") -Force
		Write-Host '[Saved]' -NoNewline -ForegroundColor Yellow; Write-Host " $($List) " -NoNewline -ForegroundColor Cyan; Write-Host "to $((Join-Path $Path -ChildPath "$($list).json"))" -ForegroundColor Green
	}
	Write-Verbose "[$(Get-Date -Format HH:mm:ss) DONE]"
} #end Function

$scriptblock = {
	param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
	if ([bool]($PSDefaultParameterValues.Keys -like '*:GitHubUserID')) {(Get-PWSHModuleList).name | Where-Object {$_ -like "*$wordToComplete*"}}
}
Register-ArgumentCompleter -CommandName Save-PWSHModuleList -ParameterName ListName -ScriptBlock $scriptBlock
