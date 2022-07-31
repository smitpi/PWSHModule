
<#PSScriptInfo

.VERSION 0.1.0

.GUID 956d0d59-2167-433c-ab10-31c260546997

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
 Add a module to the config file 

#> 

<#
.SYNOPSIS
Adds a new module to the GitHub Gist List.

.DESCRIPTION
Adds a new module to the GitHub Gist List.

.PARAMETER GitHubUserID
The GitHub User ID.

.PARAMETER GitHubToken
GitHub Token with access to the Users' Gist.

.PARAMETER ListName
The File Name on GitHub Gist.

.PARAMETER ModuleName
Name of the module to add. You can also use a keyword to search for.

.PARAMETER Repository
Name of the Repository to hosting the module.

.PARAMETER RequiredVersion
This will force a version to be used. Leave blank to use the latest version.

.EXAMPLE
Add-PWSHModule -GitHubUserID smitpi -GitHubToken $GitHubToken -ListName base -ModuleName pslauncher -Repository PSgallery -RequiredVersion 0.1.19

#>
Function Add-PWSHModule {
	[Cmdletbinding(HelpURI = 'https://smitpi.github.io/PWSHModule/Add-PWSHModule')]
	PARAM(
		[Parameter(Mandatory = $true)]
		[string]$GitHubUserID, 
		[Parameter(Mandatory = $true)]
		[string]$GitHubToken,
		[Parameter(Mandatory = $true)]
		[string]$ListName,
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[Alias('Name')]
		[string[]]$ModuleName,
		[String]$Repository = 'PSGallery',
		[string]$RequiredVersion
	)

	begin {
		try {
			Write-Verbose "[$(Get-Date -Format HH:mm:ss) BEGIN] Starting $($myinvocation.mycommand)"
			$headers = @{}
			$auth = '{0}:{1}' -f $GitHubUserID, $GitHubToken
			$bytes = [System.Text.Encoding]::ASCII.GetBytes($auth)
			$base64 = [System.Convert]::ToBase64String($bytes)
			$headers.Authorization = 'Basic {0}' -f $base64

			Write-Verbose "[$(Get-Date -Format HH:mm:ss) Starting connect to github"
			$url = 'https://api.github.com/users/{0}/gists' -f $GitHubUserID
			$AllGist = Invoke-RestMethod -Uri $url -Method Get -Headers $headers -ErrorAction Stop
			$PRGist = $AllGist | Select-Object | Where-Object { $_.description -like 'PWSHModule-ConfigFile' }
		} catch {Write-Error "Can't connect to gist:`n $($_.Exception.Message)"}

		try {
			Write-Verbose "[$(Get-Date -Format HH:mm:ss) Checking Config File"
			$Content = (Invoke-WebRequest -Uri ($PRGist.files.$($ListName)).raw_url -Headers $headers).content | ConvertFrom-Json -ErrorAction Stop
		} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
		if ([string]::IsNullOrEmpty($Content.CreateDate) -or [string]::IsNullOrEmpty($Content.Modules)) {Write-Error 'Invalid Config File'}

		[System.Collections.ArrayList]$ModuleObject = @()		
		$Content.Modules | ForEach-Object {[void]$ModuleObject.Add($_)}
	}
	process {
		foreach ($ModName in $ModuleName) {
			$index = 0
			Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Finding modules"
			$FilterMod = Find-Module -Filter $ModName -Repository $Repository | ForEach-Object {
				[PSCustomObject]@{
					Index       = $index
					Name        = $_.Name
					Version     = $_.version
					Description = $_.Description
					ProjectURI  = $_.ProjectUri.AbsoluteUri
				}
				$index++
			}

			if ($filtermod.name.count -gt 1) {
				Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] More than one module found"
				$FilterMod | Select-Object Index, Name, Description | Format-Table -AutoSize -Wrap
				$num = Read-Host 'Index Number '
				$ModuleToAdd = $filtermod[$num]
			} elseif ($filtermod.name.Count -eq 1) {
				$ModuleToAdd = $filtermod
			} else {Write-Error 'Module not found'}

			if ($RequiredVersion) {
				try {
					Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Looking for versions"
					$tmp = Find-Module -Name $ModuleToAdd.name -RequiredVersion $RequiredVersion -Repository $Repository -ErrorAction Stop
					$VersionToAdd = $RequiredVersion
				} catch {	
					$index = 0
					Find-Module -Name $ModuleToAdd.name -AllVersions -Repository $Repository | ForEach-Object {
						[PSCustomObject]@{
							Index   = $index
							Version = $_.Version
						}
						$index++
					} | Tee-Object -Variable Version | Format-Table
					$versionnum = Read-Host 'Index Number '
					$VersionToAdd = $version[$versionnum].Version
				}
			} else {$VersionToAdd = 'Latest'}

			Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Create new Object"
			
			if (-not($ModuleObject.Name.Contains($ModuleToAdd.Name))) {
				[void]$ModuleObject.Add([PSCustomObject]@{
						Name        = $ModuleToAdd.Name
						Version     = $VersionToAdd
						Description = $ModuleToAdd.Description
						Repository  = $Repository
						Projecturi  = $ModuleToAdd.ProjectUri
					})
				Write-Host '[Added]' -NoNewline -ForegroundColor Yellow; Write-Host " $($ModuleToAdd.Name)" -NoNewline -ForegroundColor Cyan; Write-Host " to $($ListName)" -ForegroundColor Green
			} else {
				Write-Host '[Duplicate]' -NoNewline -ForegroundColor DarkRed; Write-Host " $($ModuleToAdd.Name)" -NoNewline -ForegroundColor Cyan; Write-Host " to $($ListName)" -ForegroundColor Green
			}

		}
	}
	end {
		$Content.Modules = $ModuleObject | Sort-Object -Property name
		$Content.ModifiedDate = "$(Get-Date -Format u)"
		$content.ModifiedUser = "$($env:USERNAME.ToLower())@$($env:USERDNSDOMAIN.ToLower())"
		try {
			Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Uploading to gist"
			$Body = @{}
			$files = @{}
			$Files["$($PRGist.files.$($ListName).Filename)"] = @{content = ( $Content | ConvertTo-Json | Out-String ) }
			$Body.files = $Files
			$Uri = 'https://api.github.com/gists/{0}' -f $PRGist.id
			$json = ConvertTo-Json -InputObject $Body
			$json = [System.Text.Encoding]::UTF8.GetBytes($json)
			$null = Invoke-WebRequest -Headers $headers -Uri $Uri -Method Patch -Body $json -ErrorAction Stop
			Write-Host '[Uploaded]' -NoNewline -ForegroundColor Yellow; Write-Host " List: $($ListName)" -NoNewline -ForegroundColor Cyan; Write-Host ' to Github Gist' -ForegroundColor Green
		} catch {Write-Error "Can't connect to gist:`n $($_.Exception.Message)"}
		Write-Verbose "[$(Get-Date -Format HH:mm:ss) DONE]"
	}
} #end Function


$scriptblock = {
	(Get-PSRepository).Name
}
Register-ArgumentCompleter -CommandName Add-PWSHModule -ParameterName Repository -ScriptBlock $scriptBlock


$scriptblock = {
	param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
	if ([bool]($PSDefaultParameterValues.Keys -like '*GitHubUserID*')) {(Show-PWSHModuleList).name}
}
Register-ArgumentCompleter -CommandName Add-PWSHModule -ParameterName ListName -ScriptBlock $scriptBlock
