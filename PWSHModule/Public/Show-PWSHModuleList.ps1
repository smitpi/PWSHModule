
<#PSScriptInfo

.VERSION 0.1.0

.GUID 791b0019-b84d-4f8d-b84e-42d07d7a9042

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
Created [13/07/2022_01:15] Initial Script Creating

.PRIVATEDATA

#>


<# 

.DESCRIPTION 
 Shows a list of all the Config files in GitHub 

#> 


<#
.SYNOPSIS
List all the GitHub Gist Lists.

.DESCRIPTION
List all the GitHub Gist Lists.

.PARAMETER GitHubUserID
The GitHub User ID.

.PARAMETER PublicGist
Select if the list is hosted publicly.

.PARAMETER GitHubToken
GitHub Token with access to the Users' Gist.

.EXAMPLE
Show-PWSHModuleList -GitHubUserID smitpi -GitHubToken $GitHubToken

#>
Function Show-PWSHModuleList {
	[Cmdletbinding(DefaultParameterSetName = 'Private', HelpURI = 'https://smitpi.github.io/PWSHModule/Show-PWSHModuleList')]
	PARAM(
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


	[System.Collections.ArrayList]$GistObject = @()
	Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Create object"
	$PRGist.files | Get-Member -MemberType NoteProperty | ForEach-Object {
		$Content = (Invoke-WebRequest -Uri ($PRGist.files.$($_.name)).raw_url -Headers $headers).content | ConvertFrom-Json -ErrorAction Stop
		if ($Content.modifiedDate -notlike 'Unknown') {
			$modifiedDate = [datetime]$Content.ModifiedDate
			$modifiedUser = $Content.ModifiedUser
		} else { 
			$modifiedDate = 'Unknown'
			$modifiedUser = 'Unknown'
		}
		[void]$GistObject.Add([PSCustomObject]@{
				Name         = $_.Name
				Description  = $Content.Description
				Date         = [datetime]$Content.CreateDate
				Author       = $Content.Author
				ModifiedDate = $modifiedDate
				ModifiedUser = $modifiedUser
			})
	}

	$GistObject
	Write-Verbose "[$(Get-Date -Format HH:mm:ss) DONE]"

} #end Function
