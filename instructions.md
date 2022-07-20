# PWSHModule
 
## Description
Creates a GitHub Gist (Private or Public) list to install and maintain the installed PowerShell Modules on your systems, you can create more than one list and use it to custom install modules from different repositories or different versions.
 
## Getting Started
- Install from PowerShell Gallery [PS Gallery](https://www.powershellgallery.com/packages/PWSHModule)
```
Install-Module -Name PWSHModule -Verbose
```
- or from GitHub [GitHub Repo](https://github.com/smitpi/PWSHModule)
```
git clone https://github.com/smitpi/PWSHModule (Join-Path (get-item (Join-Path (Get-Item $profile).Directory 'Modules')).FullName -ChildPath PWSHModule)
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
