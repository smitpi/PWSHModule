#region Public Functions
#region Add-PWSHModule.ps1
######## Function 1 of 12 ##################
# Function:         Add-PWSHModule
# Module:           PWSHModule
# ModuleVersion:    0.1.24
# Author:           Pierre Smit
# Company:          HTPCZA Tech
# CreatedOn:        2022/07/09 15:57:31
# ModifiedOn:       2022/09/18 19:40:39
# Synopsis:         Adds a new module to the GitHub Gist List.
#############################################
 
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
        }
        catch { Write-Error "Can't connect to gist:`n $($_.Exception.Message)" }
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
            }
            elseif ($filtermod.name.Count -eq 1) {
                $ModuleToAdd = $filtermod
            }
            else { Write-Error 'Module not found' }

            if ($RequiredVersion) {
                try {
                    Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Looking for versions"
                    Find-Module -Name $ModuleToAdd.name -RequiredVersion $RequiredVersion -Repository $Repository -ErrorAction Stop | Out-Null
                    $VersionToAdd = $RequiredVersion
                }
                catch {
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
            }
            else { $VersionToAdd = 'Latest' }

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
            }
            catch { Write-Warning "Error: `n`tMessage:$($_.Exception.Message)" }
            if ([string]::IsNullOrEmpty($Content.CreateDate) -or [string]::IsNullOrEmpty($Content.Modules)) { Write-Error 'Invalid Config File' }

            [System.Collections.generic.List[PSObject]]$ModuleObject = @()
            $Content.Modules | ForEach-Object { $ModuleObject.Add($_) }
			
            $NewModuleObject | ForEach-Object {
                if ($_.name -notin $ModuleObject.Name) {
                    $ModuleObject.Add($_)
                    Write-Host '[Added]' -NoNewline -ForegroundColor Yellow; Write-Host " $($_.Name)" -NoNewline -ForegroundColor Cyan; Write-Host " to List: $($List)" -ForegroundColor Green
                }
                else { Write-Host '[Duplicate]' -NoNewline -ForegroundColor red; Write-Host " $($_.Name)" -NoNewline -ForegroundColor Cyan; Write-Host " to List: $($List)" -ForegroundColor Green }
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
            }
            catch { Write-Error "Can't connect to gist:`n $($_.Exception.Message)" }
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
    Get-PWSHModuleList | ForEach-Object { $_.Name } | Where-Object { $_ -like "*$wordToComplete*" }
}
Register-ArgumentCompleter -CommandName Add-PWSHModule -ParameterName ListName -ScriptBlock $scriptBlock2
 
Export-ModuleMember -Function Add-PWSHModule
#endregion
 
#region Add-PWSHModuleDefaultsToProfile.ps1
######## Function 2 of 12 ##################
# Function:         Add-PWSHModuleDefaultsToProfile
# Module:           PWSHModule
# ModuleVersion:    0.1.24
# Author:           Pierre Smit
# Company:          HTPCZA Tech
# CreatedOn:        2022/07/31 11:51:50
# ModifiedOn:       2022/09/02 13:00:37
# Synopsis:         Creates PSDefaultParameterValues in the users profile files.
#############################################
 
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
    }
    else {
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
    }
    catch { $CheckProfile = New-Item $PROFILE -ItemType File -Force }
	
    $Files = Get-ChildItem -Path "$($CheckProfile.Directory)\*profile*"
    foreach ($file in $files) {	
        $tmp = Get-Content -Path $file.FullName | Where-Object { $_ -notlike '*PWSHModule*' }
        $tmp | Set-Content -Path $file.FullName -Force
        if (-not($RemoveConfig)) { Add-Content -Value $ToAppend -Path $file.FullName -Force -Encoding utf8 }
        Write-Host '[Updated]' -NoNewline -ForegroundColor Yellow; Write-Host ' Profile File:' -NoNewline -ForegroundColor Cyan; Write-Host " $($file.FullName)" -ForegroundColor Green
    }

} #end Function
 
Export-ModuleMember -Function Add-PWSHModuleDefaultsToProfile
#endregion
 
#region Get-PWSHModuleList.ps1
######## Function 3 of 12 ##################
# Function:         Get-PWSHModuleList
# Module:           PWSHModule
# ModuleVersion:    0.1.24
# Author:           Pierre Smit
# Company:          HTPCZA Tech
# CreatedOn:        2022/07/13 01:15:39
# ModifiedOn:       2022/09/18 17:21:05
# Synopsis:         List all the GitHub Gist Lists.
#############################################
 
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
Get-PWSHModuleList -GitHubUserID smitpi -GitHubToken $GitHubToken

#>
Function Get-PWSHModuleList {
    [Cmdletbinding(DefaultParameterSetName = 'Private', HelpURI = 'https://smitpi.github.io/PWSHModule/Get-PWSHModuleList')]
    [Alias ('Show-PWSHModuleList')]
    PARAM(
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
    }
    catch { throw "Can't connect to gist:`n $($_.Exception.Message)" }


    [System.Collections.ArrayList]$GistObject = @()
    Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Create object"
    $PRGist.files | Get-Member -MemberType NoteProperty | ForEach-Object {
        $Content = (Invoke-WebRequest -Uri ($PRGist.files.$($_.name)).raw_url -Headers $headers).content | ConvertFrom-Json -ErrorAction Stop
        if ($Content.modifiedDate -notlike 'Unknown') {
            $modifiedDate = [datetime]$Content.ModifiedDate
            $modifiedUser = $Content.ModifiedUser
        }
        else { 
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
 
Export-ModuleMember -Function Get-PWSHModuleList
#endregion
 
#region Install-PWSHModule.ps1
######## Function 4 of 12 ##################
# Function:         Install-PWSHModule
# Module:           PWSHModule
# ModuleVersion:    0.1.24
# Author:           Pierre Smit
# Company:          HTPCZA Tech
# CreatedOn:        2022/07/12 07:38:48
# ModifiedOn:       2022/09/18 19:46:56
# Synopsis:         Install modules from the specified list.
#############################################
 
<#
.SYNOPSIS
Install modules from the specified list.

.DESCRIPTION
Install modules from the specified list.

.PARAMETER ListName
The File Name on GitHub Gist.

.PARAMETER Scope
Where the module will be installed. AllUsers require admin access.

.PARAMETER AllowPrerelease
Allow the installation on beta modules.

.PARAMETER GitHubUserID
The GitHub User ID.

.PARAMETER PublicGist
Select if the list is hosted publicly.

.PARAMETER GitHubToken
GitHub Token with access to the Users' Gist.

.PARAMETER LocalList
Select if the list is saved locally.

.PARAMETER Path
Directory where files are saved.

.PARAMETER Repository
Override the repository listed in the config file.

.EXAMPLE
Install-PWSHModule -Filename extended -Scope CurrentUser -GitHubUserID smitpi -GitHubToken $GitHubToken

#>
Function Install-PWSHModule {
    [Cmdletbinding(DefaultParameterSetName = 'Private', HelpURI = 'https://smitpi.github.io/PWSHModule/Install-PWSHModule')]
    PARAM(
        [Parameter(Position = 0)]
        [string[]]$ListName,
        [Parameter(Position = 1)]
        [ValidateSet('AllUsers', 'CurrentUser')]
        [string]$Scope,
        [switch]$AllowPrerelease,
        [Parameter(Mandatory, ParameterSetName = 'Public')]
        [Parameter(Mandatory, ParameterSetName = 'Private')]
        [string]$GitHubUserID,
        [Parameter(ParameterSetName = 'Public')]
        [switch]$PublicGist,
        [Parameter(ParameterSetName = 'Private')]
        [string]$GitHubToken,
        [Parameter(ParameterSetName = 'local')]
        [switch]$LocalList,
        [Parameter(ParameterSetName = 'local')]
        [System.IO.DirectoryInfo]$Path,
        [string]$Repository
    )

    if ($scope -like 'AllUsers') {
        Write-Verbose "[$(Get-Date -Format HH:mm:ss) BEGIN] Check for admin"
        $IsAdmin = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        if (-not($IsAdmin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) { Write-Error 'Must be running an elevated prompt.' }
    }

    if ($GitHubUserID) {
        try {
            if ($PublicGist) {
                Write-Host '[Using] ' -NoNewline -ForegroundColor Yellow 
                Write-Host 'Public Gist:' -NoNewline -ForegroundColor Cyan 
                Write-Host ' for list:' -ForegroundColor Green -NoNewline 
                Write-Host "$($ListName)" -ForegroundColor Cyan
            }

            Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Connect to Gist"
            $headers = @{}
            $auth = '{0}:{1}' -f $GitHubUserID, $GitHubToken
            $bytes = [System.Text.Encoding]::ASCII.GetBytes($auth)
            $base64 = [System.Convert]::ToBase64String($bytes)
            $headers.Authorization = 'Basic {0}' -f $base64

            $url = 'https://api.github.com/users/{0}/gists' -f $GitHubUserID
            $AllGist = Invoke-RestMethod -Uri $url -Method Get -Headers $headers -ErrorAction Stop
            $PRGist = $AllGist | Select-Object | Where-Object { $_.description -like 'PWSHModule-ConfigFile' }
        }
        catch { Write-Error "Can't connect to gist:`n $($_.Exception.Message)" }
    }
    [System.Collections.generic.List[PSObject]]$CombinedModules = @()
    foreach ($List in $ListName) {
        try {
            Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Checking Config File"
            if ($LocalList) {
                $ListPath = Join-Path $Path -ChildPath "$($list).json"
                if (Test-Path $ListPath) { 
                    Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Collecting Content"
                    $Content = Get-Content $ListPath | ConvertFrom-Json
                }
                else { Write-Warning "List file $($List) does not exist" }
            }
            else {
                Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Collecting Content"
                $Content = (Invoke-WebRequest -Uri ($PRGist.files.$($List)).raw_url -Headers $headers).content | ConvertFrom-Json -ErrorAction Stop
            }
            if ([string]::IsNullOrEmpty($Content.CreateDate) -or [string]::IsNullOrEmpty($Content.Modules)) { Write-Error 'Invalid Config File' }
            Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Adding to list."
            $Content.Modules | Where-Object { $_ -notlike $null -and $_.name -notin $CombinedModules.name } | ForEach-Object { $CombinedModules.Add($_) }
        }
        catch { Write-Warning "Error: `n`tMessage:$($_.Exception)" }
    }

    foreach ($module in ($CombinedModules | Sort-Object -Property name -Unique)) {
        Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Checking for installed module"
        $InstallModuleSettings = @{
            AllowClobber       = $true
            Force              = $true
            SkipPublisherCheck = $true
            Repository         = $module.Repository
            Scope              = $Scope
        }
        if ($AllowPrerelease) { $InstallModuleSettings.add('AllowPrerelease', $true) }
        if ($Repository) { $InstallModuleSettings.Repository = $Repository }

        if ($module.Version -like 'Latest') {
            $mod = Get-Module -Name $module.Name
            if (-not($mod)) { $mod = Get-Module -Name $module.name -ListAvailable }
            if (-not($mod)) { 
                try {
                    Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Installing module"
                    Write-Host '[Installing] ' -NoNewline -ForegroundColor Yellow ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name)" -ForegroundColor Green -NoNewline ; Write-Host ' to scope: ' -ForegroundColor DarkRed -NoNewline ; Write-Host "$($scope)" -ForegroundColor Cyan
                    Install-Module -Name $module.Name @InstallModuleSettings
                }
                catch { Write-Warning "Error: `n`tMessage:$($_.Exception.Message)" }
            }
            else {
                try {
                    Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Checking versions"
                    Write-Host '[Installed] ' -NoNewline -ForegroundColor Green ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name) " -ForegroundColor Green -NoNewline ; Write-Host "$($mod.Path)" -ForegroundColor DarkRed
                    $OnlineMod = Find-Module -Name $module.name -Repository $InstallModuleSettings.Repository
                    [version]$Onlineversion = $OnlineMod.version 
                    [version]$Localversion = ($mod | Sort-Object -Property Version -Descending)[0].Version
                }
                catch { Write-Warning "Error: `n`tMessage:$($_.Exception.Message)" }
                if ($Localversion -lt $Onlineversion) {
                    Write-Host "`t[Upgrading] " -NoNewline -ForegroundColor Yellow ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name)" -ForegroundColor Green -NoNewline; Write-Host " v$($OnlineMod.version)" -ForegroundColor DarkRed
                    try {
                        Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Updating module"
                        Update-Module -Name $module.Name -Force -ErrorAction Stop
                    }
                    catch {
                        try {
                            Install-Module -Name $module.name @InstallModuleSettings
                        }
                        catch { Write-Warning "Error: `n`tMessage:$($_.Exception.Message)" }
                    }
                    Get-Module $module.name -ListAvailable | Remove-Module -Force -ErrorAction SilentlyContinue
                    $mods = (Get-Module $module.name -ListAvailable | Sort-Object -Property version -Descending) | Select-Object -Skip 1
                    foreach ($mod in $mods) {
                        Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] UnInstalling module"
                        Write-Host "`t[Uninstalling] " -NoNewline -ForegroundColor Yellow ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name)($($mod.Version)) " -ForegroundColor Green -NoNewline ; Write-Host "$($mod.Path)" -ForegroundColor DarkRed
                        try {
                            Uninstall-Module -Name $mod.name -RequiredVersion $mod.Version -Force
                        }
                        catch { Write-Warning "Error: `n`tMessage:$($_.Exception.Message)" }
                    }
                }
            }
        }
        else {
            Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Checking installed module"
            $mod = Get-Module -Name $module.Name
            if (-not($mod)) { $mod = Get-Module -Name $module.name -ListAvailable }
            if ((-not($mod)) -or $mod.Version -lt $module.Version) {
                try {
                    Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Installing module"
                    Write-Host '[Installing] ' -NoNewline -ForegroundColor Yellow ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name)($($module.Version))" -ForegroundColor Green -NoNewline ; Write-Host ' to scope: ' -ForegroundColor DarkRed -NoNewline ; Write-Host "$($scope)" -ForegroundColor Cyan
                    Install-Module -Name $module.Name -RequiredVersion $module.Version @InstallModuleSettings
                }
                catch { Write-Warning "Error: `n`tMessage:$($_.Exception.Message)" }
            }
            else {
                Write-Host '[Installed] ' -NoNewline -ForegroundColor Green ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name) " -ForegroundColor Green -NoNewline ; Write-Host "$($mod.Path)" -ForegroundColor DarkRed
            }
        }
        Write-Verbose "[$(Get-Date -Format HH:mm:ss) DONE]"
    }

} #end Function


$scriptblock = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    Get-PWSHModuleList | ForEach-Object { $_.Name } | Where-Object { $_ -like "*$wordToComplete*" }
}
Register-ArgumentCompleter -CommandName Install-PWSHModule -ParameterName ListName -ScriptBlock $scriptBlock

$scriptblock1 = {
	(Get-PSRepository).Name
}
Register-ArgumentCompleter -CommandName Install-PWSHModule -ParameterName Repository -ScriptBlock $scriptBlock1

 
Export-ModuleMember -Function Install-PWSHModule
#endregion
 
#region Move-PWSHModuleBetweenScope.ps1
######## Function 5 of 12 ##################
# Function:         Move-PWSHModuleBetweenScope
# Module:           PWSHModule
# ModuleVersion:    0.1.24
# Author:           Pierre Smit
# Company:          HTPCZA Tech
# CreatedOn:        2022/08/20 12:38:44
# ModifiedOn:       2022/09/10 03:15:16
# Synopsis:         Moves modules between scopes (CurrentUser and AllUsers).
#############################################
 
<#
.SYNOPSIS
Moves modules between scopes (CurrentUser and AllUsers).

.DESCRIPTION
Moves modules between scopes (CurrentUser and AllUsers).

.PARAMETER SourceScope
From where the modules will be copied.

.PARAMETER DestinationScope
To there the modules will be copied.

.PARAMETER ModuleName
Name of the modules to move. You can select multiple names or you can use * to select all.

.PARAMETER Repository
The repository will be used to install the module at the destination.

.EXAMPLE
Move-PWSHModuleBetweenScope -SourceScope D:\Documents\PowerShell\Modules -DestinationScope C:\Program Files\PowerShell\Modules -ModuleName PWSHMOdule -Repository psgallery

#>
Function Move-PWSHModuleBetweenScope {
    [Cmdletbinding(HelpURI = 'https://smitpi.github.io/PWSHModule/Move-PWSHModuleBetweenScope')]
    [OutputType([System.Object[]])]
    PARAM(
        [Parameter(Mandatory = $true)]
        [ValidateScript( { $IsAdmin = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
                if ($IsAdmin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { $True }
                else { Throw 'Must be running an elevated prompt.' } })]
        [System.IO.DirectoryInfo]$SourceScope,

        [Parameter(Mandatory = $true)]
        [System.IO.DirectoryInfo]$DestinationScope,

        [Parameter(ValueFromPipeline)]
        [Alias('Name')]
        [string[]]$ModuleName = 'All',

        [string]$Repository = 'PSGallery'
    )

    if ($ModuleName -like 'All') { $ModuleName = (Get-ChildItem -Path $($SourceScope) -Directory).Name }

    foreach ($mod in $ModuleName) {
        $CheckModInFolder = Get-ChildItem -Path (Join-Path $SourceScope -ChildPath "$($mod)\*\$($mod).psm1") | Sort-Object -Property directory -Descending | Select-Object -First 1
        if ([string]::IsNullOrEmpty($CheckModInFolder)) {
            Write-Warning "$($mod) is not a valid module in folder: $($SourceScope)"
        }
        else {
            Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Checking for installed module $($mod)"
            try {
                $CheckModule = Get-Module -FullyQualifiedName $CheckModInFolder.FullName -ListAvailable
                if ($CheckModule.Version.ToString() -eq '0.0') { [version]$ModuleVersion = (Import-PowerShellDataFile $CheckModInFolder.FullName.Replace('psm1', 'psd1')).ModuleVersion }
                else { [version]$ModuleVersion = $CheckModule.Version }
                Remove-Module $mod -Force -ErrorAction SilentlyContinue
            }
            catch { Write-Warning "Did not find $($ModuleName) in $($SourceScope)" }
            Write-Host '[Moving] ' -NoNewline -ForegroundColor Yellow ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($CheckModule.Name)($($CheckModule.Version)) " -ForegroundColor Green -NoNewline ; Write-Host "$($DestinationScope)" -ForegroundColor DarkRed			
            try {
                Write-Verbose "[$(Get-Date -Format HH:mm:ss) ADDING] to archive"
				    (Get-Item $CheckModule.Path).directory.Parent.FullName | Compress-Archive -DestinationPath (Join-Path -Path $SourceScope -ChildPath 'PWSHModule_Move.zip') -Update -ErrorAction Stop
                Write-Verbose "[$(Get-Date -Format HH:mm:ss) Deleteing folder"
    				(Get-Item $CheckModule.Path).directory.Parent.FullName | Remove-Item -Recurse -Force -ErrorAction Stop
                Write-Verbose "[$(Get-Date -Format HH:mm:ss) Saving] Module $($MoveMod.name)"
                Save-Module -Name $CheckModule.Name -RequiredVersion $ModuleVersion -Repository $Repository -Force -AcceptLicense -Path (Get-Item $DestinationScope).FullName -ErrorAction Stop
            }
            catch { Write-Warning "Error: `n`tMessage:$($_.Exception.Message)" }
            Write-Verbose "[$(Get-Date -Format HH:mm:ss) Complete"
        }
    }
} #end Function
$scriptblock = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    $env:PSModulePath.Split(';') | ForEach-Object { """$($_)""" }
}
Register-ArgumentCompleter -CommandName Move-PWSHModuleBetweenScope -ParameterName SourceScope -ScriptBlock $scriptBlock
Register-ArgumentCompleter -CommandName Move-PWSHModuleBetweenScope -ParameterName DestinationScope -ScriptBlock $scriptBlock

$scriptblock3 = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
	(Get-Repository).name | Where-Object { $_ -like "*$wordToComplete*" }
}
Register-ArgumentCompleter -CommandName Move-PWSHModuleBetweenScope -ParameterName Repository -ScriptBlock $scriptBlock3
 
Export-ModuleMember -Function Move-PWSHModuleBetweenScope
#endregion
 
#region New-PWSHModuleList.ps1
######## Function 6 of 12 ##################
# Function:         New-PWSHModuleList
# Module:           PWSHModule
# ModuleVersion:    0.1.24
# Author:           Pierre Smit
# Company:          HTPCZA Tech
# CreatedOn:        2022/07/09 15:22:20
# ModifiedOn:       2022/09/19 01:31:11
# Synopsis:         Add a new list to GitHub Gist.
#############################################
 
<#
.SYNOPSIS
Add a new list to GitHub Gist.

.DESCRIPTION
Add a new list to GitHub Gist.

.PARAMETER ListName
The File Name on GitHub Gist.

.PARAMETER Description
Summary of the function for the list.

.PARAMETER GitHubUserID
The GitHub User ID.

.PARAMETER GitHubToken
GitHub Token with access to the Users' Gist.

.EXAMPLE
New-PWSHModuleList -ListName Base -Description "These modules needs to be installed on all servers"  -GitHubUserID smitpi -GitHubToken $GitHubToken

#>
Function New-PWSHModuleList {
    [Cmdletbinding(SupportsShouldProcess = $true, HelpURI = 'https://smitpi.github.io/PWSHModule/New-PWSHModuleList')]
    PARAM(
        [Parameter(Mandatory)]
        [string]$ListName,
        [Parameter(Mandatory)]
        [string]$Description,
        [Parameter(Mandatory)]
        [string]$GitHubUserID, 
        [Parameter(Mandatory)]
        [string]$GitHubToken
    )
    if ($pscmdlet.ShouldProcess('Target', 'Operation')) {
        Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Creating config"
        $NewConfig = [PSCustomObject]@{
            CreateDate   = (Get-Date -Format u)
            Description  = $Description
            Author       = "$($env:USERNAME.ToLower())"
            ModifiedDate = 'Unknown'
            ModifiedUser = 'Unknown'
            Modules      = [PSCustomObject]@{
                Name        = 'PWSHModule'
                Version     = 'Latest'
                Description = 'Uses a GitHub Gist File to install and maintain a list of PowerShell Modules'
                Repository  = 'PSGallery'
                Projecturi  = 'https://github.com/smitpi/PWSHModule'
            }
        } | ConvertTo-Json

        $ConfigFile = Join-Path $env:TEMP -ChildPath "$($ListName).json"
        Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Create temp file"
        if (Test-Path $ConfigFile) {
            Write-Warning "Config File exists, Renaming file to $($ListName)-$(Get-Date -Format yyyyMMdd_HHmm).json"	
            try {
                Rename-Item $ConfigFile -NewName "$($ListName)-$(Get-Date -Format yyyyMMdd_HHmm).json" -Force -ErrorAction Stop | Out-Null
            }
            catch { Write-Warning "Error: `n`tMessage:$($_.Exception.Message);exit" }
        }
        try {
            $NewConfig | Set-Content -Path $ConfigFile -Encoding utf8 -ErrorAction Stop
        }
        catch { Write-Warning "Error: `n`tMessage:$($_.Exception.Message)" }


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
        }
        catch { Write-Error "Can't connect to gist:`n $($_.Exception.Message)" }

		
        if ([string]::IsNullOrEmpty($PRGist)) {
            try {
                Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Uploading to gist"
                $Body = @{}
                $files = @{}
                $Files["$($ListName)"] = @{content = ( Get-Content (Get-Item $ConfigFile).FullName -Encoding UTF8 | Out-String ) }
                $Body.files = $Files
                $Body.description = 'PWSHModule-ConfigFile'
                $json = ConvertTo-Json -InputObject $Body
                $json = [System.Text.Encoding]::UTF8.GetBytes($json)
                $null = Invoke-WebRequest -Headers $headers -Uri https://api.github.com/gists -Method Post -Body $json -ErrorAction Stop
                Write-Host '[Uploaded]' -NoNewline -ForegroundColor Yellow; Write-Host " $($ListName).json" -NoNewline -ForegroundColor Cyan; Write-Host ' to Github Gist' -ForegroundColor Green

            }
            catch { Write-Error "Can't connect to gist:`n $($_.Exception.Message)" }
        }
        else {
            try {
                Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Uploading to Gist"
                $Body = @{}
                $files = @{}
                $Files["$($ListName)"] = @{content = ( Get-Content (Get-Item $ConfigFile).FullName -Encoding UTF8 | Out-String ) }
                $Body.files = $Files
                $Uri = 'https://api.github.com/gists/{0}' -f $PRGist.id
                $json = ConvertTo-Json -InputObject $Body
                $json = [System.Text.Encoding]::UTF8.GetBytes($json)
                $null = Invoke-WebRequest -Headers $headers -Uri $Uri -Method Patch -Body $json -ErrorAction Stop
                Write-Host '[Uploaded]' -NoNewline -ForegroundColor Yellow; Write-Host " $($ListName).json" -NoNewline -ForegroundColor Cyan; Write-Host ' to Github Gist' -ForegroundColor Green
            }
            catch { Write-Error "Can't connect to gist:`n $($_.Exception.Message)" }
        }
        Write-Verbose "[$(Get-Date -Format HH:mm:ss) DONE]"
    }
} #end Function
 
Export-ModuleMember -Function New-PWSHModuleList
#endregion
 
#region Remove-PWSHModule.ps1
######## Function 7 of 12 ##################
# Function:         Remove-PWSHModule
# Module:           PWSHModule
# ModuleVersion:    0.1.24
# Author:           Pierre Smit
# Company:          HTPCZA Tech
# CreatedOn:        2022/07/13 11:14:06
# ModifiedOn:       2022/09/18 19:44:11
# Synopsis:         Remove module from the specified list.
#############################################
 
<#
.SYNOPSIS
Remove module from the specified list.

.DESCRIPTION
Remove module from the specified list.

.PARAMETER GitHubUserID
The GitHub User ID.

.PARAMETER GitHubToken
GitHub Token with access to the Users' Gist.

.PARAMETER ListName
The File Name on GitHub Gist.

.PARAMETER ModuleName
Module to remove.

.PARAMETER UninstallModule
Will uninstall the modules as well.

.EXAMPLE
Remove-PWSHModule -ListName base -ModuleName pslauncher -GitHubUserID smitpi -GitHubToken $GitHubToken
#>
Function Remove-PWSHModule {
    [Cmdletbinding(SupportsShouldProcess = $true, HelpURI = 'https://smitpi.github.io/PWSHModule/Remove-PWSHModule')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    PARAM(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string[]]$ListName,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Name')]
        [string[]]$ModuleName,
        [Parameter(Mandatory)]
        [string]$GitHubUserID,
        [Parameter(Mandatory)]
        [string]$GitHubToken,
        [ValidateScript( { $IsAdmin = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
                if ($IsAdmin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { $True }
                else { Throw 'Must be running an elevated prompt.' } })]
        [switch]$UninstallModule
    )
    begin {
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
        }
        catch { Write-Error "Can't connect to gist:`n $($_.Exception.Message)" }
    }
    process {
        if ($pscmdlet.ShouldProcess('Target', 'Operation')) {
            foreach ($List in $ListName) {
                try {
                    Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Checking config file."
                    $Content = (Invoke-WebRequest -Uri ($PRGist.files.$($List)).raw_url -Headers $headers).content | ConvertFrom-Json -ErrorAction Stop
                }
                catch { Write-Warning "Error: `n`tMessage:$($_.Exception.Message)" }
                if ([string]::IsNullOrEmpty($Content.CreateDate) -or [string]::IsNullOrEmpty($Content.Modules)) { Write-Error 'Invalid Config File' }

                [System.Collections.ArrayList]$ModuleObject = @()
                $Content.Modules | ForEach-Object { [void]$ModuleObject.Add($_)
                }
                foreach ($mod in $ModuleName) {
                    Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Find module to remove"
                    $Modremove = ($Content.Modules | Where-Object { $_.Name -like "*$Mod*" })
                    if ([string]::IsNullOrEmpty($Modremove) -or ($Modremove.name.count -gt 1)) {
                        Write-Error 'Module not found. Redefine your search'
                    }
                    else {
                        Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Removing module"
                        $ModuleObject.Remove($Modremove)
                        Write-Host '[Removed]' -NoNewline -ForegroundColor Yellow; Write-Host " $($Modremove.Name)" -NoNewline -ForegroundColor Cyan; Write-Host " from $($ListName)" -ForegroundColor Green
                        if ($UninstallModule) {
                            try {
                                Write-Host '[Uninstalling]' -NoNewline -ForegroundColor Yellow ; Write-Host 'All Versions of Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($mod) " -ForegroundColor Green
                                Uninstall-Module -Name $mod -AllVersions -Force -ErrorAction Stop
                            }
                            catch {
                                Write-Warning "Error: `n`tMessage:$($_.Exception.Message)"
                                Get-Module -Name $Mod -ListAvailable | ForEach-Object {
                                    try {
                                        Write-Host '[Deleting] ' -NoNewline -ForegroundColor Yellow ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($_.Name)($($_.Version)) " -ForegroundColor Green -NoNewline ; Write-Host "$($_.Path)" -ForegroundColor DarkRed
                                        $Directory = Join-Path -Path (Get-Item $_.Path).FullName -ChildPath '..\..\' -Resolve
                                        Remove-Item -Path $Directory -Recurse -Force -ErrorAction Stop
                                    }
                                    catch { Write-Warning "Error: `n`tMessage:$($_.Exception.Message)" }
                                }
                            }
                        }
                    }
                }
                try {
                    $Content.Modules = $ModuleObject | Sort-Object -Property name
                    $Content.ModifiedDate = "$(Get-Date -Format u)"
                    $content.ModifiedUser = "$($env:USERNAME.ToLower())"
                    Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Uploading to gist"
                    $Body = @{}
                    $files = @{}
                    $Files["$($PRGist.files.$($List).Filename)"] = @{content = ( $Content | ConvertTo-Json | Out-String ) }
                    $Body.files = $Files
                    $Uri = 'https://api.github.com/gists/{0}' -f $PRGist.id
                    $json = ConvertTo-Json -InputObject $Body
                    $json = [System.Text.Encoding]::UTF8.GetBytes($json)
                    $null = Invoke-WebRequest -Headers $headers -Uri $Uri -Method Patch -Body $json -ErrorAction Stop
                    Write-Host '[Uploaded] ' -NoNewline -ForegroundColor Yellow; Write-Host " List: $($List)" -NoNewline -ForegroundColor Cyan; Write-Host ' to Github Gist' -ForegroundColor Green
                }
                catch { Write-Error "Can't connect to gist:`n $($_.Exception.Message)" }
            }
        }
    }
    end {}
} #end Function
$scriptblock = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    Get-PWSHModuleList | ForEach-Object { $_.Name } | Where-Object { $_ -like "*$wordToComplete*" }
}
Register-ArgumentCompleter -CommandName Remove-PWSHModule -ParameterName ListName -ScriptBlock $scriptBlock

$scriptblock2 = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    Show-PWSHModule -ListName $fakeBoundParameters.Listname -ErrorAction SilentlyContinue | ForEach-Object { $_.Name } | Where-Object { $_ -like "*$wordToComplete*" }
}
Register-ArgumentCompleter -CommandName Remove-PWSHModule -ParameterName ModuleName -ScriptBlock $scriptBlock2
 
Export-ModuleMember -Function Remove-PWSHModule
#endregion
 
#region Remove-PWSHModuleList.ps1
######## Function 8 of 12 ##################
# Function:         Remove-PWSHModuleList
# Module:           PWSHModule
# ModuleVersion:    0.1.24
# Author:           Pierre Smit
# Company:          HTPCZA Tech
# CreatedOn:        2022/07/31 11:14:51
# ModifiedOn:       2022/09/19 01:32:25
# Synopsis:         Deletes a list from GitHub Gist
#############################################
 
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
        }
        catch { throw "Can't connect to gist:`n $($_.Exception.Message)" }

        foreach ($List in $ListName) {
            Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Create object"
            $CheckExist = $PRGist.files | Get-Member -MemberType NoteProperty | Where-Object { $_.name -like $List }
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
                }
                catch { Write-Error "Can't connect to gist:`n $($_.Exception.Message)" }
            }
            Write-Verbose "[$(Get-Date -Format HH:mm:ss) DONE]"
        }
    }
} #end Function

$scriptblock = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    Get-PWSHModuleList | ForEach-Object { $_.Name } | Where-Object { $_ -like "*$wordToComplete*" }
}
Register-ArgumentCompleter -CommandName Remove-PWSHModuleList -ParameterName ListName -ScriptBlock $scriptBlock
 
Export-ModuleMember -Function Remove-PWSHModuleList
#endregion
 
#region Save-PWSHModule.ps1
######## Function 9 of 12 ##################
# Function:         Save-PWSHModule
# Module:           PWSHModule
# ModuleVersion:    0.1.24
# Author:           Pierre Smit
# Company:          HTPCZA Tech
# CreatedOn:        2022/07/13 10:26:41
# ModifiedOn:       2022/09/18 19:42:06
# Synopsis:         Saves the modules from the specified list to a folder.
#############################################
 
<#
.SYNOPSIS
Saves the modules from the specified list to a folder.

.DESCRIPTION
Saves the modules from the specified list to a folder.

.PARAMETER ListName
The File Name on GitHub Gist.

.PARAMETER AsNuGet
Save in the NuGet format

.PARAMETER AddPathToPSModulePath
Add path to environmental variable PSModulePath.

.PARAMETER Path
Where to save.

.PARAMETER Repository
Override the repository listed in the config file.

.PARAMETER GitHubUserID
The GitHub User ID.

.PARAMETER PublicGist
Select if the list is hosted publicly.

.PARAMETER GitHubToken
GitHub Token with access to the Users' Gist.

.PARAMETER LocalList
Select if the list is saved locally.

.PARAMETER ListPath
Directory where list files are saved.

.EXAMPLE
Save-PWSHModule -ListName extended -AsNuGet -Path c:\temp\ -GitHubUserID smitpi -GitHubToken $GitHubToken

#>
Function Save-PWSHModule {
    [Cmdletbinding(DefaultParameterSetName = 'Private', HelpURI = 'https://smitpi.github.io/PWSHModule/Save-PWSHModule')]
    PARAM(
        [Parameter(Mandatory, Position = 0)]
        [string[]]$ListName,
		
        [Parameter(Mandatory, ParameterSetName = 'nuget')]
        [Parameter(ParameterSetName = 'public')]
        [Parameter(ParameterSetName = 'private')]
        [Parameter(ParameterSetName = 'local')]
        [switch]$AsNuGet,
			
        [ValidateScript( { if (Test-Path $_) { $true }
                else { New-Item -Path $_ -ItemType Directory -Force | Out-Null; $true }
            })]
        [Parameter(Mandatory)]
        [System.IO.DirectoryInfo]$Path,

        [ValidateScript( { $IsAdmin = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
                if ($IsAdmin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { $True }
                else { Throw 'Must be running an elevated prompt.' } })]
        [switch]$AddPathToPSModulePath,

        [string]$Repository,
		
        [Parameter(mandatory, ParameterSetName = 'public')]
        [Parameter(mandatory, ParameterSetName = 'private')]
        [string]$GitHubUserID, 
		
        [Parameter(mandatory, ParameterSetName = 'public')]
        [switch]$PublicGist,
		
        [Parameter(mandatory, ParameterSetName = 'private')]
        [string]$GitHubToken,
		
        [Parameter(mandatory, ParameterSetName = 'local')]
        [switch]$LocalList,
		
        [Parameter(mandatory, ParameterSetName = 'local')]
        [System.IO.DirectoryInfo]$ListPath
    )

    if ($GitHubUserID) {
        try {
            if ($PublicGist) {
                Write-Host '[Using] ' -NoNewline -ForegroundColor Yellow 
                Write-Host 'Public Gist:' -NoNewline -ForegroundColor Cyan 
                Write-Host ' for list:' -ForegroundColor Green -NoNewline 
                Write-Host "$($ListName)" -ForegroundColor Cyan
            }

            Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Connect to Gist"
            $headers = @{}
            $auth = '{0}:{1}' -f $GitHubUserID, $GitHubToken
            $bytes = [System.Text.Encoding]::ASCII.GetBytes($auth)
            $base64 = [System.Convert]::ToBase64String($bytes)
            $headers.Authorization = 'Basic {0}' -f $base64

            $url = 'https://api.github.com/users/{0}/gists' -f $GitHubUserID
            $AllGist = Invoke-RestMethod -Uri $url -Method Get -Headers $headers -ErrorAction Stop
            $PRGist = $AllGist | Select-Object | Where-Object { $_.description -like 'PWSHModule-ConfigFile' }
        }
        catch { Write-Error "Can't connect to gist:`n $($_.Exception.Message)" }
    }
    [System.Collections.generic.List[PSObject]]$CombinedModules = @()
    foreach ($List in $ListName) {
        try {
            Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Checking Config File"
            if ($LocalList) {
                $ListPath = Join-Path $ListPath -ChildPath "$($list).json"
                if (Test-Path $ListPath) { 
                    Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Collecting Content"
                    $Content = Get-Content $ListPath | ConvertFrom-Json
                }
                else { Write-Warning "List file $($List) does not exist" }
            }
            else {
                Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Collecting Content"
                $Content = (Invoke-WebRequest -Uri ($PRGist.files.$($List)).raw_url -Headers $headers).content | ConvertFrom-Json -ErrorAction Stop
            }
            if ([string]::IsNullOrEmpty($Content.CreateDate) -or [string]::IsNullOrEmpty($Content.Modules)) { Write-Error 'Invalid Config File' }
            Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Adding to list."
            $Content.Modules | Where-Object { $_ -notlike $null -and $_.name -notin $CombinedModules.name } | ForEach-Object { $CombinedModules.Add($_) }
        }
        catch { Write-Warning "Error: `n`tMessage:$($_.Exception)" }
    }

    foreach ($module in ($CombinedModules | Sort-Object -Property name -Unique)) {
        if ($Repository) { $UseRepo = $Repository }
        else { $UseRepo = $module.Repository }
        if ($module.Version -like 'Latest') {
            if ($AsNuGet) {
                try {
                    Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Downloading"
                    Write-Host '[Downloading] ' -NoNewline -ForegroundColor Yellow ; Write-Host 'NuGet: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name) " -ForegroundColor Green -NoNewline ; Write-Host "Path: $($Path)" -ForegroundColor DarkRed
                    Save-Package -Name $module.Name -Provider NuGet -Source (Get-PSRepository -Name $UseRepo).SourceLocation -Path $Path.FullName | Out-Null
                }
                catch { Write-Warning "Error: `n`tMessage:$($_.Exception.Message)" }
            }
            else {
                try {
                    Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Downloading"
                    Write-Host '[Downloading] ' -NoNewline -ForegroundColor Yellow ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name) " -ForegroundColor Green -NoNewline ; Write-Host "Path: $($Path)" -ForegroundColor DarkRed
                    Save-Module -Name $module.name -Repository $UseRepo -Path $Path.FullName -Force -AcceptLicense
                }
                catch { Write-Warning "Error: `n`tMessage:$($_.Exception.Message)" }
            }
        }
        else {
            if ($AsNuGet) {
                try {
                    Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Downloading"
                    Write-Host '[Downloading] ' -NoNewline -ForegroundColor Yellow ; Write-Host 'NuGet: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name)(ver $($module.version)) " -ForegroundColor Green -NoNewline ; Write-Host "Path: $($Path)" -ForegroundColor DarkRed
                    Save-Package -Name $module.Name -Provider NuGet -Source (Get-PSRepository -Name $UseRepo).SourceLocation -RequiredVersion $module.Version -Path $Path.FullName | Out-Null
                }
                catch { Write-Warning "Error: `n`tMessage:$($_.Exception.Message)" }
            }
            else {
                try {
                    Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Downloading"
                    Write-Host '[Downloading] ' -NoNewline -ForegroundColor Yellow ; Write-Host 'Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name)(ver $($module.version)) " -ForegroundColor Green -NoNewline ; Write-Host "Path: $($Path)" -ForegroundColor DarkRed
                    Save-Module -Name $module.name -Repository $UseRepo -RequiredVersion $module.Version -Path $Path.FullName -Force -AcceptLicense
                }
                catch { Write-Warning "Error: `n`tMessage:$($_.Exception.Message)" }
            }

        }
    }
	
    if ($AddPathToPSModulePath) {
        try {
            $NugetCheck = Get-ChildItem -Path "$($Path.FullName)\*.nupkg"
            if (($env:PSModulePath.Split(';') -notcontains $Path.FullName) -and (-not($NugetCheck))) {
                $key = (Get-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager').OpenSubKey('Environment', $true)
                $regpath = $key.GetValue('PSModulePath', '', 'DoNotExpandEnvironmentNames')
                $regpath += ";$($path.FullName)"
                $key.SetValue('PSModulePath', $regpath, [Microsoft.Win32.RegistryValueKind]::ExpandString)
                Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Downloading"
                Write-Host '[Adding] ' -NoNewline -ForegroundColor Yellow ; Write-Host 'Path: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($path.FullName) " -ForegroundColor Green -NoNewline ; Write-Host 'to: $env:PSModulePath' -ForegroundColor Green
            }
            else {
                if ($NugetCheck) { Write-Warning "Can't add nuget repository to PSModulePath. Path needs to be extracted modules folders." }
                else { Write-Host '[Adding] ' -NoNewline -ForegroundColor Yellow ; Write-Host 'Path: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($path.FullName) " -ForegroundColor Green -NoNewline ; Write-Host 'to: $env:PSModulePath' -ForegroundColor Green -NoNewline; Write-Host ' - Already added.' -ForegroundColor DarkRed }
            }
        }
        catch { Write-Warning "Error: `n`tMessage:$($_.Exception.Message)" }
    }
    Write-Verbose "[$(Get-Date -Format HH:mm:ss) DONE]"

}#end Function


$scriptblock = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    Get-PWSHModuleList | ForEach-Object { $_.Name } | Where-Object { $_ -like "*$wordToComplete*" }
}
Register-ArgumentCompleter -CommandName Save-PWSHModule -ParameterName ListName -ScriptBlock $scriptBlock

$scriptblock1 = {
	(Get-PSRepository).Name
}
Register-ArgumentCompleter -CommandName Save-PWSHModule -ParameterName Repository -ScriptBlock $scriptBlock1

 
Export-ModuleMember -Function Save-PWSHModule
#endregion
 
#region Save-PWSHModuleList.ps1
######## Function 10 of 12 ##################
# Function:         Save-PWSHModuleList
# Module:           PWSHModule
# ModuleVersion:    0.1.24
# Author:           Pierre Smit
# Company:          HTPCZA Tech
# CreatedOn:        2022/09/07 16:36:26
# ModifiedOn:       2022/09/18 19:44:58
# Synopsis:         Save the Gist file to a local file
#############################################
 
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
    }
    catch { throw "Can't connect to gist:`n $($_.Exception.Message)" }

    foreach ($List in $ListName) {
        try {
            Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Checking Config File"
            $Content = (Invoke-WebRequest -Uri ($PRGist.files.$($List)).raw_url -Headers $headers).content | ConvertFrom-Json -ErrorAction Stop
        }
        catch { Write-Warning "Error: `n`tMessage:$($_.Exception.Message)" }
        if ([string]::IsNullOrEmpty($Content.CreateDate) -or [string]::IsNullOrEmpty($Content.Modules)) { Write-Error 'Invalid Config File' }
        $Content | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $Path -ChildPath "$($list).json") -Force
        Write-Host '[Saved]' -NoNewline -ForegroundColor Yellow; Write-Host " $($List) " -NoNewline -ForegroundColor Cyan; Write-Host "to $((Join-Path $Path -ChildPath "$($list).json"))" -ForegroundColor Green
    }
    Write-Verbose "[$(Get-Date -Format HH:mm:ss) DONE]"
} #end Function

$scriptblock = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    Get-PWSHModuleList | ForEach-Object { $_.Name } | Where-Object { $_ -like "*$wordToComplete*" }
}
Register-ArgumentCompleter -CommandName Save-PWSHModuleList -ParameterName ListName -ScriptBlock $scriptBlock
 
Export-ModuleMember -Function Save-PWSHModuleList
#endregion
 
#region Show-PWSHModule.ps1
######## Function 11 of 12 ##################
# Function:         Show-PWSHModule
# Module:           PWSHModule
# ModuleVersion:    0.1.24
# Author:           Pierre Smit
# Company:          HTPCZA Tech
# CreatedOn:        2022/07/09 15:57:20
# ModifiedOn:       2022/09/02 12:43:12
# Synopsis:         Show the details of the modules in a list.
#############################################
 
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
    }
    catch { throw "Can't connect to gist:`n $($_.Exception.Message)" }

    [System.Collections.ArrayList]$ModuleObject = @()		
    $index = 0
    foreach ($List in $ListName) {
        try {
            Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Checking config file"
            $Content = (Invoke-WebRequest -Uri ($PRGist.files.$($List)).raw_url -Headers $headers).content | ConvertFrom-Json -ErrorAction Stop
        }
        catch { Write-Warning "Error: `n`tMessage:$($_.Exception.Message)" }
        if ([string]::IsNullOrEmpty($Content.CreateDate) -or [string]::IsNullOrEmpty($Content.Modules)) { Throw 'Invalid Config File' }

        Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Creating object"
        $Content.Modules | ForEach-Object {				
            [void]$ModuleObject.Add([PSCustomObject]@{
                    Index       = $index
                    Name        = $_.Name
                    List        = $List
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
                }
                else {
                    $online = Find-Module -Name $CompareModule.name -Repository $CompareModule.Repository -RequiredVersion $CompareModule.Version
                }
                Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Local: $($CompareModule.name)"
                $local = $null
                $local = Get-Module -Name $CompareModule.Name -ListAvailable | Sort-Object -Property Version -Descending | Select-Object -First 1
                if ([string]::IsNullOrEmpty($local)) {
                    $InstallVer = 'NotInstalled'
                    $InstallCount = 'NotInstalled'
                    $InstallFolder = 'NotInstalled'
                }
                else {
                    $InstallVer = $local.Version
                    $InstallCount = (Get-Module -Name $CompareModule.Name -ListAvailable).count
                    $InstallFolder = (Get-Item $local.Path).DirectoryName
                }
                if ($local.Version -lt $online.Version) { $update = $true }
                else { $update = $false }
                Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Building List with module: $($CompareModule.name)"
                [void]$CompareObject.Add([PSCustomObject]@{
                        Index           = $index
                        Name            = $CompareModule.Name
                        List            = $CompareModule.List
                        Publisheddate   = [datetime]$online.PublishedDate
                        UpdateDate      = [datetime]$online.AdditionalMetadata.lastUpdated
                        InstalledVer    = $InstallVer
                        OnlineVer       = $online.Version
                        UpdateAvailable = $update
                        InstallCount    = $InstallCount
                        Folder          = $InstallFolder
                        Description     = $CompareModule.Description
                        Repository      = $CompareModule.Repository
                    })
            }
            catch { Write-Warning "Error $($CompareModule.Name): `n`tMessage:$($_.Exception.Message)" }
            $index++
        }
        $CompareObject
    }
    else { $ModuleObject }
    if ($ShowProjectURI) {
        Write-Output ' '
        [int]$IndexURI = Read-Host 'Module Index Number'
        if (-not([string]::IsNullOrEmpty($Content.Modules[$IndexURI].projecturi))) {
            Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] open url"
            Start-Process "$($Content.Modules[$IndexURI].projecturi)"
        }
        else { Write-Warning 'NotInstalled ProjectURI' }
        Write-Verbose "[$(Get-Date -Format HH:mm:ss) DONE]"
    }
} #end Function


$scriptblock = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    if ([bool]($PSDefaultParameterValues.Keys -like "*:GitHubUserID")) { (Show-PWSHModuleList).name | Where-Object { $_ -like "*$wordToComplete*" } }
}
Register-ArgumentCompleter -CommandName Show-PWSHModule -ParameterName ListName -ScriptBlock $scriptBlock
 
Export-ModuleMember -Function Show-PWSHModule
#endregion
 
#region Uninstall-PWSHModule.ps1
######## Function 12 of 12 ##################
# Function:         Uninstall-PWSHModule
# Module:           PWSHModule
# ModuleVersion:    0.1.24
# Author:           Pierre Smit
# Company:          HTPCZA Tech
# CreatedOn:        2022/07/20 19:06:13
# ModifiedOn:       2022/09/18 19:45:59
# Synopsis:         Will uninstall the module from the system.
#############################################
 
<#
.SYNOPSIS
Will uninstall the module from the system.

.DESCRIPTION
Will uninstall the module from the system. Select OldVersions to remove duplicates only.

.PARAMETER ListName
The File Name on GitHub Gist.

.PARAMETER ModuleName
Name of the module to uninstall. Use * to select all modules in the list.

.PARAMETER UninstallOldVersions
Will uninstall old versions of All modules.

.PARAMETER ForceUninstall
Will force delete the base folder if uninstall fail.

.PARAMETER GitHubUserID
The GitHub User ID.

.PARAMETER PublicGist
Select if the list is hosted publicly.

.PARAMETER GitHubToken
GitHub Token with access to the Users' Gist.

.EXAMPLE
Uninstall-PWSHModule  -ListName base -OldVersions -GitHubUserID smitpi -PublicGist

#>
Function Uninstall-PWSHModule {
    [Cmdletbinding(DefaultParameterSetName = 'Private', HelpURI = 'https://smitpi.github.io/PWSHModule/Install-PWSHModule')]
    PARAM(
        [Parameter(Position = 0, Mandatory, ParameterSetName = 'List')]
        [ValidateScript( { $IsAdmin = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
                if ($IsAdmin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { $True }
                else { Throw 'Must be running an elevated prompt.' } })]
        [string[]]$ListName,

        [Parameter(Position = 1, Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'List')]
        [Alias('Name')]
        [string[]]$ModuleName,

        [Parameter(Position = 0, ParameterSetName = 'OldVersions')]
        [switch]$UninstallOldVersions,

        [Parameter(Position = 1, ParameterSetName = 'OldVersions')]
        [switch]$ForceUninstall,

        [Parameter(Mandatory, ParameterSetName = 'List')]
        [string]$GitHubUserID,

        [Parameter(ParameterSetName = 'Public')]
        [Parameter(ParameterSetName = 'List')]
        [switch]$PublicGist,

        [Parameter(ParameterSetName = 'Private')]
        [Parameter(ParameterSetName = 'List')]
        [string]$GitHubToken
    )

    begin {
        if (-not($UninstallOldVersions)) {
            try {
                Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Connect to Gist"
                $headers = @{}
                $auth = '{0}:{1}' -f $GitHubUserID, $GitHubToken
                $bytes = [System.Text.Encoding]::ASCII.GetBytes($auth)
                $base64 = [System.Convert]::ToBase64String($bytes)
                $headers.Authorization = 'Basic {0}' -f $base64

                $url = 'https://api.github.com/users/{0}/gists' -f $GitHubUserID
                $AllGist = Invoke-RestMethod -Uri $url -Method Get -Headers $headers -ErrorAction Stop
                $PRGist = $AllGist | Select-Object | Where-Object { $_.description -like 'PWSHModule-ConfigFile' }
            }
            catch { Write-Error "Can't connect to gist:`n $($_.Exception.Message)" }
        }
    }
    process {
        foreach ($List in $ListName) {
            try {
                Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Checking Config File"
                $Content = (Invoke-WebRequest -Uri ($PRGist.files.$($List)).raw_url -Headers $headers).content | ConvertFrom-Json -ErrorAction Stop
            }
            catch { Write-Warning "Error: `n`tMessage:$($_.Exception.Message)" }
            if ([string]::IsNullOrEmpty($Content.CreateDate) -or [string]::IsNullOrEmpty($Content.Modules)) { Write-Error 'Invalid Config File' }
            [System.Collections.ArrayList]$CollectObject = @()

            foreach ($collectmod in $ModuleName) {
                $Content.Modules | Where-Object { $_.name -like $collectmod } | ForEach-Object { [void]$CollectObject.Add($_) }
            }
			
        }
    }
    end {
        foreach ($module in ($CollectObject | Select-Object -Unique) ) {
            Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Checking for installed module"
            try {
                Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Uninstalling module $($module.Name)"
                Write-Host '[Uninstalling]' -NoNewline -ForegroundColor Yellow ; Write-Host 'All Versions of Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($module.Name) " -ForegroundColor Green
                Uninstall-Module -Name $module.Name -AllVersions -Force -ErrorAction Stop
            }
            catch { Write-Warning "Error: `n`tMessage:$($_.Exception.Message)" }
        }
        Write-Verbose "[$(Get-Date -Format HH:mm:ss) DONE]"
	
        if ($UninstallOldVersions) {
            Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Checking for duplicate module"
            $DuplicateMods = Get-Module -list | Where-Object path -NotMatch 'windows\\system32' | Group-Object -Property name | Where-Object count -GT 1
            foreach ($Duplicate in $DuplicateMods) {
                $Duplicate.Group | Sort-Object -Property version -Descending | Select-Object -Skip 1 | ForEach-Object {
                    Write-Host '[Uninstalling]' -NoNewline -ForegroundColor Yellow ; Write-Host ' Duplicate Module: ' -NoNewline -ForegroundColor Cyan ; Write-Host "$($Duplicate.Name) " -ForegroundColor Green -NoNewline ; Write-Host " [$($_.version)] - $($_.path) " -ForegroundColor DarkRed
                    Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Uninstalling duplicate $($Duplicate.Name) $($_.Path)"
                    try {
                        Uninstall-Module -Name $Duplicate.Name -RequiredVersion $_.Version -Force -AllowPrerelease -ErrorAction Stop
                    }
                    catch {
                        Write-Warning "Uninstall for module $($Duplicate.Name) Failed.`n`tMessage:$($_.Exception.Message)"
                        if ($ForceUninstall) {
                            try {
                                Write-Verbose "[$(Get-Date -Format HH:mm:ss) PROCESS] Uninstalling duplicate $($Duplicate.Name) $($_.Path) - Force delete folder"
                                $Modpath = Get-Item (Join-Path $Duplicate.Group[1].Path -ChildPath '..\' -Resolve)
                                $Modpath | Remove-Item -Recurse -Force
                            }
                            catch { Write-Warning "Error: `n`tMessage:$($_.Exception.Message)" }
                        }
                    }
                }
                Write-Verbose "[$(Get-Date -Format HH:mm:ss) DONE] $($Duplicate.Name)"
            }
        }
    }
} #end Function


$scriptblock = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    Get-PWSHModuleList | ForEach-Object { $_.Name } | Where-Object { $_ -like "*$wordToComplete*" }
}
Register-ArgumentCompleter -CommandName Uninstall-PWSHModule -ParameterName ListName -ScriptBlock $scriptBlock

$scriptblock2 = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    Show-PWSHModule -ListName $fakeBoundParameters.Listname -ErrorAction SilentlyContinue | ForEach-Object { $_.Name } | Where-Object { $_ -like "*$wordToComplete*" }
}
Register-ArgumentCompleter -CommandName Uninstall-PWSHModule -ParameterName ModuleName -ScriptBlock $scriptBlock2

 
Export-ModuleMember -Function Uninstall-PWSHModule
#endregion
 
#endregion
 
