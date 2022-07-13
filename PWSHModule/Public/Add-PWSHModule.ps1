
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
#Requires -Module PSWriteColor
<# 

.DESCRIPTION 
 Add a module to the config file 

#> 


<#
.SYNOPSIS
Add a Module name to the config File.

.DESCRIPTION
Add a Module name to the config File.

.PARAMETER Path
Path to the json config file.

.PARAMETER ModuleName
Name of the Module to add.

.PARAMETER Repository
Repository to find the module.

.PARAMETER RequiredVersion
Select if you want to specify a specific version.

.EXAMPLE
Add-PWSHModule -Path C:\Utils\PWSLModule.json -ModuleName Json -Repository PSGallery

#>
Function Add-PWSHModule {
	[Cmdletbinding(DefaultParameterSetName = 'Set1', HelpURI = 'https://smitpi.github.io/PWSHModule/Add-PWSHModule')]
	PARAM(
		[string]$GitHubUserID, 
		[string]$GitHubToken,
		[string]$ListName,
		[Parameter(Mandatory = $true)]
		[string]$ModuleName,
		[String]$Repository = 'PSGallery',
		[switch]$RequiredVersion
	)

	try {
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
		$Content = (Invoke-WebRequest -Uri ($PRGist.files.$($ListName)).raw_url -Headers $headers).content | ConvertFrom-Json -ErrorAction Stop
	} catch {Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"}
	if ([string]::IsNullOrEmpty($Content.CreateDate) -or [string]::IsNullOrEmpty($Content.Modules)) {Throw 'Invalid Config File'}


	[System.Collections.ArrayList]$ModuleObject = @()		
	$Content.Modules | ForEach-Object {[void]$ModuleObject.Add($_)}
	$index = 0
	$FilterMod = Find-Module -Filter $ModuleName -Repository $Repository | ForEach-Object {
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
		$FilterMod | Select-Object Index, Name, Description | Format-Table -AutoSize -Wrap
		$num = Read-Host 'Index Number '
		$ModuleToAdd = $filtermod[$num]
	} elseif ($filtermod.name.Count -eq 1) {
		$ModuleToAdd = $filtermod
	} else {throw 'Module not found'}

	if ($RequiredVersion) {
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
	} else {$VersionToAdd = 'Latest'}

	[void]$ModuleObject.Add([PSCustomObject]@{
			Name        = $ModuleToAdd.Name
			Version     = $VersionToAdd
			Description = $ModuleToAdd.Description
			Repository  = $Repository
			Projecturi  = $ModuleToAdd.ProjectUri
		})
	Write-Host '[Added]' -NoNewline -ForegroundColor Yellow; Write-Host " $($ModuleToAdd.Name)" -NoNewline -ForegroundColor Cyan; Write-Host " to $($ListName)" -ForegroundColor Green
	$Content.Modules = $ModuleObject | Sort-Object -Property name
	$Content.Modified = "[$(Get-Date -Format u)] -- $($env:USERNAME.ToLower())@$($env:USERDNSDOMAIN.ToLower())"

	try {
		$Body = @{}
		$files = @{}
		$Files["$($PRGist.files.$($ListName).Filename)"] = @{content = ( $Content | ConvertTo-Json | Out-String ) }
		$Body.files = $Files
		$Uri = 'https://api.github.com/gists/{0}' -f $PRGist.id
		$json = ConvertTo-Json -InputObject $Body
		$json = [System.Text.Encoding]::UTF8.GetBytes($json)
		$null = Invoke-WebRequest -Headers $headers -Uri $Uri -Method Patch -Body $json -ErrorAction Stop
		Write-Host '[Uploaded]' -NoNewline -ForegroundColor Yellow; Write-Host " $($ListName).json" -NoNewline -ForegroundColor Cyan; Write-Host ' to Github Gist' -ForegroundColor Green
	} catch {throw "Can't connect to gist:`n $($_.Exception.Message)"}

} #end Function
