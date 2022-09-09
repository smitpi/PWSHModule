# PWSHModule
 
## Description
Creates a GitHub (Private or Public) Gist to install and maintain the installed PowerShell Modules on your systems, you can create more than one list and use it to custom install modules from different repositories or different versions.
 
## Getting Started
- Install from PowerShell Gallery [PS Gallery](https://www.powershellgallery.com/packages/PWSHModule)
```
Install-Module -Name PWSHModule -Verbose
```
- or run this script to install from GitHub [GitHub Repo](https://github.com/smitpi/PWSHModule)
```
$CurrentLocation = Get-Item .
$ModuleDestination = (Join-Path (Get-Item (Join-Path (Get-Item $profile).Directory 'Modules')).FullName -ChildPath PWSHModule)
git clone --depth 1 https://github.com/smitpi/PWSHModule $ModuleDestination 2>&1 | Write-Host -ForegroundColor Yellow
Set-Location $ModuleDestination
git filter-branch --prune-empty --subdirectory-filter Output HEAD 2>&1 | Write-Host -ForegroundColor Yellow
Set-Location $CurrentLocation
```
- Then import the module into your session
```
Import-Module PWSHModule -Verbose -Force
```
- or run these commands for more help and details.
```
Get-Command -Module PWSHModule
Get-Help about_PWSHModule
```
Documentation can be found at: [Github_Pages](https://smitpi.github.io/PWSHModule)
