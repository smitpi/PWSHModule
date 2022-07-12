# PWSHModule
 
## Description
Uses a Config file to install and maintain a list of PowerShell Modules
 
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
 
## Functions
- [`Add-PWSHModule`](https://smitpi.github.io/PWSHModule/Add-PWSHModule) -- Add a module to the config file
- [`Install-PWSHModule`](https://smitpi.github.io/PWSHModule/Install-PWSHModule) -- Install modules from a config file
- [`New-PWSHModuleConfigFile`](https://smitpi.github.io/PWSHModule/New-PWSHModuleConfigFile) -- Create a new config file.
- [`Remove-PWSHModule`](https://smitpi.github.io/PWSHModule/Remove-PWSHModule) -- Remove a module to the config file
- [`Show-PWSHModule`](https://smitpi.github.io/PWSHModule/Show-PWSHModule) -- List the content of a config file
