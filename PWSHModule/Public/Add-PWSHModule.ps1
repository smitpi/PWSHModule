
<#PSScriptInfo

.VERSION 0.1.0

.GUID 9dd484ac-5162-49b4-8fc4-057d26eae6ee

.AUTHOR Pierre Smit

.COMPANYNAME HTPCZA Tech

.COPYRIGHT

.TAGS

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


.PRIVATEDATA

#>

<# 

.DESCRIPTION 
 Adds a new module to the GitHub Gist List. 

#> 



<#
.SYNOPSIS
Adds a new module to the GitHub Gist List.

.DESCRIPTION
Adds a new module to the GitHub Gist List.

.PARAMETER ListName
The File Name on GitHub Gist.

.PARAMETER ModuleName
Name of the module to add. You can also use a keyword to search for.

.PARAMETER Repository
Name of the Repository to hosting the module.

.PARAMETER RequiredVersion
This will force a version to be used. Leave blank to use the latest version.

.PARAMETER GitHubUserID
The GitHub User ID.

.PARAMETER GitHubToken
GitHub Token with access to the Users' Gist.

.EXAMPLE
Add-PWSHModule -ListName base -ModuleName pslauncher -Repository PSgallery -RequiredVersion 0.1.19 -GitHubUserID smitpi -GitHubToken $GitHubToken

#>
Function Add-PWSHModule {
	[Cmdletbinding(HelpURI = 'https://smitpi.github.io/PWSHModule/Add-PWSHModule')]
	PARAM(
		[Parameter(Mandatory)]
		[string[]]$ListName,
		[Parameter(Mandatory, ValueFromPipeline)]
		[Alias('Name')]
		[string[]]$ModuleName,
		[String]$Repository = 'PSGallery',
		[string]$RequiredVersion,
		[Parameter(Mandatory = $true)]
		[string]$GitHubUserID,
		[Parameter(Mandatory = $true)]
		[string]$GitHubToken
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
		[System.Collections.generic.List[PSObject]]$NewModuleObject = @()
	}
	process {
		foreach ($ModName in $ModuleName) {
			Write-Host '[Searching]' -NoNewline -ForegroundColor Yellow; Write-Host ' for Module: ' -NoNewline -ForegroundColor Cyan; Write-Host "$($ModName)" -ForegroundColor Green
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
					Find-Module -Name $ModuleToAdd.name -RequiredVersion $RequiredVersion -Repository $Repository -ErrorAction Stop | Out-Null
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
			$NewModuleObject.Add([PSCustomObject]@{
					Name        = $ModuleToAdd.Name
					Version     = $VersionToAdd
					Description = $ModuleToAdd.Description
					Repository  = $Repository
					Projecturi  = $ModuleToAdd.ProjectUri
				})
				
		}
	}
	end {
		foreach ($List in $ListName) {
			try {
				Write-Verbose "[$(Get-Date -Format HH:mm:ss) Checking Config File"
				$Content = (Invoke-WebRequest -Uri ($PRGist.files.$($List)).raw_url -Headers $headers).content | ConvertFrom-Json -ErrorAction Stop
			} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
			if ([string]::IsNullOrEmpty($Content.CreateDate) -or [string]::IsNullOrEmpty($Content.Modules)) {Write-Error 'Invalid Config File'}

			[System.Collections.generic.List[PSObject]]$ModuleObject = @()
			$Content.Modules | ForEach-Object {$ModuleObject.Add($_)}
			
			$NewModuleObject | ForEach-Object {
				if ($_.name -notin $ModuleObject.Name) {
					$ModuleObject.Add($_)
					Write-Host '[Added]' -NoNewline -ForegroundColor Yellow; Write-Host " $($_.Name)" -NoNewline -ForegroundColor Cyan; Write-Host " to List: $($List)" -ForegroundColor Green
				} else {Write-Host '[Duplicate]' -NoNewline -ForegroundColor red; Write-Host " $($_.Name)" -NoNewline -ForegroundColor Cyan; Write-Host " to List: $($List)" -ForegroundColor Green}
			}

			$Content.Modules = $ModuleObject | Sort-Object -Property name
			$Content.ModifiedDate = "$(Get-Date -Format u)"
			$content.ModifiedUser = "$($env:USERNAME.ToLower())"
			try {
				Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Uploading to gist"
				$Body = @{}
				$files = @{}
				$Files["$($PRGist.files.$($List).Filename)"] = @{content = ( $Content | ConvertTo-Json | Out-String ) }
				$Body.files = $Files
				$Uri = 'https://api.github.com/gists/{0}' -f $PRGist.id
				$json = ConvertTo-Json -InputObject $Body
				$json = [System.Text.Encoding]::UTF8.GetBytes($json)
				$null = Invoke-WebRequest -Headers $headers -Uri $Uri -Method Patch -Body $json -ErrorAction Stop
				Write-Host '[Uploaded]' -NoNewline -ForegroundColor Yellow; Write-Host " List: $($List)" -NoNewline -ForegroundColor Cyan; Write-Host ' to Github Gist' -ForegroundColor Green
			} catch {Write-Error "Can't connect to gist:`n $($_.Exception.Message)"}
			Write-Verbose "[$(Get-Date -Format HH:mm:ss) DONE]"
		}
	}
} #end Function


$scriptblock = {
	(Get-PSRepository).Name
}
Register-ArgumentCompleter -CommandName Add-PWSHModule -ParameterName Repository -ScriptBlock $scriptBlock


$scriptblock2 = {
	param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
	Get-PWSHModuleList | ForEach-Object {$_.Name} | Where-Object {$_ -like "*$wordToComplete*"}
}
Register-ArgumentCompleter -CommandName Add-PWSHModule -ParameterName ListName -ScriptBlock $scriptBlock2
