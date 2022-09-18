
<#PSScriptInfo

.VERSION 0.1.0

.GUID d48d47f8-4dae-416a-ac6f-cb5e24adcb58

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
Created [31/07/2022_11:14] Initial Script Creating

.PRIVATEDATA

#>

#Requires -Module PSWriteColor

<# 

.DESCRIPTION 
 Deletes a list from GitHub Gist 

#> 

<#
.SYNOPSIS
Deletes a list from GitHub Gist

.DESCRIPTION
Deletes a list from GitHub Gist

.PARAMETER ListName
The Name of the list to remove.

.PARAMETER GitHubUserID
The GitHub User ID.

.PARAMETER GitHubToken
GitHub Token with access to the Users' Gist.

.EXAMPLE
Remove-PWSHModuleList -ListName Base  -GitHubUserID smitpi -GitHubToken $GitHubToken

#>
Function Remove-PWSHModuleList {
	[Cmdletbinding(SupportsShouldProcess = $true, HelpURI = 'https://smitpi.github.io/PWSHModule/Remove-PWSHModuleList')]
	[OutputType([System.Object[]])]
	PARAM(
		[Parameter(Mandatory = $true)]
		[string[]]$ListName,
		[Parameter(Mandatory = $true)]
		[string]$GitHubUserID, 
		[Parameter(Mandatory = $true)]
		[string]$GitHubToken
	)


	if ($pscmdlet.ShouldProcess('Target', 'Operation')) {
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
			Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Create object"
			$CheckExist = $PRGist.files | Get-Member -MemberType NoteProperty | Where-Object {$_.name -like $List}
			if (-not([string]::IsNullOrEmpty($CheckExist))) {
				try {
					Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Remove list from Gist"
					$Body = @{}
					$files = @{}
					$Files["$($List)"] = $null
					$Body.files = $Files
					$Uri = 'https://api.github.com/gists/{0}' -f $PRGist.id
					$json = ConvertTo-Json -InputObject $Body
					$json = [System.Text.Encoding]::UTF8.GetBytes($json)
					$null = Invoke-WebRequest -Headers $headers -Uri $Uri -Method Patch -Body $json -ErrorAction Stop
					Write-Host '[Removed]' -NoNewline -ForegroundColor Yellow; Write-Host " $($List)" -NoNewline -ForegroundColor Cyan; Write-Host ' from Github Gist' -ForegroundColor DarkRed
					Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] updated gist."
				} catch {Write-Error "Can't connect to gist:`n $($_.Exception.Message)"}
			}
			Write-Verbose "[$(Get-Date -Format HH:mm:ss) DONE]"
		}
	}
} #end Function

$scriptblock = {
	param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
	Get-PWSHModuleList | ForEach-Object {$_.Name} | Where-Object {$_ -like "*$wordToComplete*"}
}
Register-ArgumentCompleter -CommandName Remove-PWSHModuleList -ParameterName ListName -ScriptBlock $scriptBlock
