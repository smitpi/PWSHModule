
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


<# 

.DESCRIPTION 
 List the content of a config file 

#> 


<#
.SYNOPSIS
Show the details of the modules in a list.

.DESCRIPTION
Show the details of the modules in a list.

.PARAMETER GitHubUserID
The GitHub User ID.

.PARAMETER GitHubToken
GitHub Token with access to the Users' Gist.

.PARAMETER ListName
The File Name on GitHub Gist.

.PARAMETER AsTable
Display output as a table.

.PARAMETER ShowProjectURI
Will open the browser to the the project URL.

.EXAMPLE
Show-PWSHModule -GitHubUserID smitpi -GitHubToken $GitHubToken -ListName Base -AsTable


#>
Function Show-PWSHModule {
	[Cmdletbinding(HelpURI = 'https://smitpi.github.io/PWSHModule/Show-PWSHModule')]
	PARAM(
		[Parameter(Mandatory = $true)]
		[string]$GitHubUserID, 
		[Parameter(Mandatory = $true)]
		[string]$GitHubToken,
		[Parameter(Mandatory = $true)]
		[string]$ListName,
		[switch]$AsTable,
		[switch]$ShowProjectURI
	)

	try {
		Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Connecting to Gist"
		$headers = @{}
		$auth = '{0}:{1}' -f $GitHubUserID, $GitHubToken
		$bytes = [System.Text.Encoding]::ASCII.GetBytes($auth)
		$base64 = [System.Convert]::ToBase64String($bytes)
		$headers.Authorization = 'Basic {0}' -f $base64

		$url = 'https://api.github.com/users/{0}/gists' -f $GitHubUserID
		$AllGist = Invoke-RestMethod -Uri $url -Method Get -Headers $headers -ErrorAction Stop
		$PRGist = $AllGist | Select-Object | Where-Object { $_.description -like 'PWSHModule-ConfigFile' }
	} catch {throw "Can't connect to gist:`n $($_.Exception.Message)"}

	try {
		Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Checking config file"
		$Content = (Invoke-WebRequest -Uri ($PRGist.files.$($Listname)).raw_url -Headers $headers).content | ConvertFrom-Json -ErrorAction Stop
	} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
	if ([string]::IsNullOrEmpty($Content.CreateDate) -or [string]::IsNullOrEmpty($Content.Modules)) {Throw 'Invalid Config File'}

	$index = 0
	Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Creating object"
	[System.Collections.ArrayList]$ModuleObject = @()		
	$Content.Modules | ForEach-Object {				
		[void]$ModuleObject.Add([PSCustomObject]@{
				Index       = $index
				Name        = $_.Name
				Version     = $_.version
				Description = $_.Description
				Repository  = $_.$Repository
				Projecturi  = $_.projecturi
			})
		$index++
	}

	if ($AsTable) {$ModuleObject | Format-Table -AutoSize}
	else {$ModuleObject}

	if ($ShowProjectURI) {
		Write-Output ' '
		[int]$IndexURI = Read-Host 'Module Index Number'

		if (-not([string]::IsNullOrEmpty($Content.Modules[$IndexURI].projecturi))) {
			Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] open url"
			Start-Process "$($Content.Modules[$IndexURI].projecturi)"
		} else { Write-Warning 'Unknown ProjectURI'}
		Write-Verbose "[$(Get-Date -Format HH:mm:ss) DONE]"
	}
} #end Function
