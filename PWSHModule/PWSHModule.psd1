#
# Module manifest for module 'PWSHModule'
#
# Generated by: Pierre Smit
#
# Generated on: 2022-09-07 18:00:45Z
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'PWSHModule.psm1'

# Version number of this module.
ModuleVersion = '0.1.17.2'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = '52868a1c-8b05-4db5-9ee3-1efdd0b0c6a5'

# Author of this module
Author = 'Pierre Smit'

# Company or vendor of this module
CompanyName = 'HTPCZA Tech'

# Copyright statement for this module
Copyright = '(c) 2022 Pierre Smit. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Creates a GitHub (Private or Public) Gist to install and maintain the installed PowerShell Modules on your systems, you can create more than one list and use it to custom install modules from different repositories or different versions.'

# Minimum version of the Windows PowerShell engine required by this module
# PowerShellVersion = ''

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = 'Add-PWSHModule', 'Add-PWSHModuleDefaultsToProfile', 
               'Get-PWSHModuleList', 'Install-PWSHModule', 
               'Move-PWSHModuleBetweenScope', 'New-PWSHModuleList', 
               'Remove-PWSHModule', 'Remove-PWSHModuleList', 'Save-PWSHModule', 
               'Save-PWSHModuleList', 'Show-PWSHModule', 'Uninstall-PWSHModule'

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
# VariablesToExport = @()

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = 'modules','powershell','ps','pwsh'

        # A URL to the license for this module.
        LicenseUri = 'https://raw.githubusercontent.com/smitpi/PWSHModule/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/smitpi/PWSHModule'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = 'Updated [20/08/2022_23:22] Added a module move script'

        # Prerelease string of this module
        # Prerelease = ''

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        # ExternalModuleDependencies = @()

    } # End of PSData hashtable

 } # End of PrivateData hashtable

# HelpInfo URI of this module
HelpInfoURI = 'https://smitpi.github.io/PWSHModule/'

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

