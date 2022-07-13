
<#PSScriptInfo

.VERSION 0.1.0

.GUID c609d747-8b88-44c5-9f8b-da9e1c72acfd

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
 Remove a module to the config file 

#> 


<#
.SYNOPSIS
Remove a module to the config file

.DESCRIPTION
Remove a module to the config file

.PARAMETER Export
Export the result to a report file. (Excel or html). Or select Host to display the object on screen.

.PARAMETER ReportPath
Where to save the report.

.EXAMPLE
Remove-PWSHModule -Export HTML -ReportPath C:\temp

#>
Function Remove-PWSHModule {
	[Cmdletbinding(DefaultParameterSetName = 'Set1', HelpURI = 'https://smitpi.github.io/PWSHModule/Remove-PWSHModule')]
	PARAM(
		[string]$GitHubUserID, 
		[string]$GitHubToken,
		[string]$ListName,
		[String]$ModuleName
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

	$Modremove = $Content.Modules | Where-Object {$_.Name -like $ModuleName}
	if ([string]::IsNullOrEmpty($Modremove) -or ($Modremove.name.count -gt 1)) {
		throw 'Module not found'
	} else {
		[System.Collections.ArrayList]$ModuleObject = @()		
		$Content.Modules | ForEach-Object {[void]$ModuleObject.Add($_)}
		$ModuleObject.Remove($Modremove)
		Write-Host '[Removed]' -NoNewline -ForegroundColor Yellow; Write-Host " $($Modremove.Name)" -NoNewline -ForegroundColor Cyan; Write-Host " to $($ListName)" -ForegroundColor Green
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
	}

} #end Function
