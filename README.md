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
 
## Functions
- [`Add-PWSHModule`](https://smitpi.github.io/PWSHModule/Add-PWSHModule) -- Adds a new module to the GitHub Gist List.
- [`Add-PWSHModuleDefaultsToProfile`](https://smitpi.github.io/PWSHModule/Add-PWSHModuleDefaultsToProfile) -- Creates PSDefaultParameterValues in the users profile files.
- [`Install-PWSHModule`](https://smitpi.github.io/PWSHModule/Install-PWSHModule) -- Install modules from the specified list.
- [`New-PWSHModuleList`](https://smitpi.github.io/PWSHModule/New-PWSHModuleList) -- Add a new list to GitHub Gist.
- [`Remove-PWSHModuleList`](https://smitpi.github.io/PWSHModule/Remove-PWSHModuleList) -- Deletes a list from GitHub Gist
- [`Save-PWSHModule`](https://smitpi.github.io/PWSHModule/Save-PWSHModule) -- Saves the modules from the specified list to a folder.
- [`Show-PWSHModule`](https://smitpi.github.io/PWSHModule/Show-PWSHModule) -- Show the details of the modules in a list.
- [`Show-PWSHModuleList`](https://smitpi.github.io/PWSHModule/Show-PWSHModuleList) -- List all the GitHub Gist Lists.
- [`Uninstall-PWSHModule`](https://smitpi.github.io/PWSHModule/Uninstall-PWSHModule) -- Will uninstall the module from the system.
