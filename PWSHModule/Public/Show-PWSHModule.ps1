
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

.PARAMETER ListName
The File Name on GitHub Gist.

.PARAMETER CompareInstalled
Compare the list to what is installed.

.PARAMETER ShowProjectURI
Will open the browser to the the project URL.

.PARAMETER GitHubUserID
The GitHub User ID.

.PARAMETER PublicGist
Select if the list is hosted publicly.

.PARAMETER GitHubToken
GitHub Token with access to the Users' Gist.

.EXAMPLE
Show-PWSHModule -ListName Base -GitHubUserID smitpi -GitHubToken $GitHubToken

#>
Function Show-PWSHModule {
	[Cmdletbinding(DefaultParameterSetName = 'Private', HelpURI = 'https://smitpi.github.io/PWSHModule/Show-PWSHModule')]
	PARAM(		
		[Parameter(Mandatory = $true)]
		[string[]]$ListName,
		[switch]$CompareInstalled,
		[switch]$ShowProjectURI,
		[Parameter(Mandatory = $true)]
		[string]$GitHubUserID, 
		[Parameter(ParameterSetName = 'Public')]
		[switch]$PublicGist,
		[Parameter(ParameterSetName = 'Private')]
		[string]$GitHubToken
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

	[System.Collections.ArrayList]$ModuleObject = @()		
	foreach ($List in $ListName) {
		try {
			Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Checking config file"
			$Content = (Invoke-WebRequest -Uri ($PRGist.files.$($List)).raw_url -Headers $headers).content | ConvertFrom-Json -ErrorAction Stop
		} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
		if ([string]::IsNullOrEmpty($Content.CreateDate) -or [string]::IsNullOrEmpty($Content.Modules)) {Throw 'Invalid Config File'}

		$index = 0
		Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Creating object"
		$Content.Modules | ForEach-Object {				
			[void]$ModuleObject.Add([PSCustomObject]@{
					Index       = $index
					Name        = $_.Name
					Version     = $_.version
					Description = $_.Description
					Repository  = $_.Repository
					Projecturi  = $_.projecturi
				})
			$index++
		}
	}
	if ($CompareInstalled) {
		[System.Collections.ArrayList]$CompareObject = @()		
		$index = 0
		foreach ($CompareModule in $ModuleObject) {
			try {
				Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Online: $($CompareModule.name)"
				if ($CompareModule.Version -like 'Latest') {
					$online = Find-Module -Name $CompareModule.name -Repository $CompareModule.Repository 
				} else {
					$online = Find-Module -Name $CompareModule.name -Repository $CompareModule.Repository -RequiredVersion $CompareModule.Version
				}
				Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Local: $($CompareModule.name)"
				$local = $null
				$local = Get-Module -Name $CompareModule.Name -ListAvailable | Sort-Object -Property Version -Descending | Select-Object -First 1
				if ([string]::IsNullOrEmpty($local)) {
					$InstallVer = 'NotInstalled'
					$InstallCount = 'NotInstalled'
					$InstallFolder = 'NotInstalled'
				} else {
					$InstallVer = $local.Version
					$InstallCount = (Get-Module -Name $CompareModule.Name -ListAvailable).count
					$InstallFolder = (Get-Item $local.Path).DirectoryName
				}
				if ($local.Version -lt $online.Version) {$update = $true}
				else {$update = $false}
				Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Building List with module: $($CompareModule.name)"
				[void]$CompareObject.Add([PSCustomObject]@{
						Index           = $index
						Name            = $CompareModule.Name
						InstalledVer    = $InstallVer
						OnlineVer       = $online.Version
						UpdateAvailable = $update
						InstallCount    = $InstallCount
						Folder          = $InstallFolder
						Description     = $CompareModule.Description
						Repository      = $CompareModule.Repository
					})
			} catch {Write-Warning "Error $($CompareModule.Name): `n`tMessage:$($_.Exception.Message)"}
			$index++
		}
		$CompareObject
	} else {$ModuleObject}
	if ($ShowProjectURI) {
		Write-Output ' '
		[int]$IndexURI = Read-Host 'Module Index Number'
		if (-not([string]::IsNullOrEmpty($Content.Modules[$IndexURI].projecturi))) {
			Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] open url"
			Start-Process "$($Content.Modules[$IndexURI].projecturi)"
		} else { Write-Warning 'NotInstalled ProjectURI'}
		Write-Verbose "[$(Get-Date -Format HH:mm:ss) DONE]"
	}
} #end Function


$scriptblock = {
	param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
	if ([bool]($PSDefaultParameterValues.Keys -like '*PWSHModule*:GitHubUserID')) {(Show-PWSHModuleList).name}
}
Register-ArgumentCompleter -CommandName Show-PWSHModule -ParameterName ListName -ScriptBlock $scriptBlock
