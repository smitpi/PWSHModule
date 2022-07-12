
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

#Requires -Module ImportExcel
#Requires -Module PSWriteHTML
#Requires -Module PSWriteColor

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
		[Cmdletbinding(DefaultParameterSetName='Set1', HelpURI = "https://smitpi.github.io/PWSHModule/Remove-PWSHModule")]
	    [OutputType([System.Object[]])]
                PARAM(
					[Parameter(Mandatory = $true)]
					[Parameter(ParameterSetName = 'Set1')]
					[ValidateScript( { (Test-Path $_) -and ((Get-Item $_).Extension -eq ".csv") })]
					[System.IO.FileInfo]$InputObject,

					[ValidateNotNullOrEmpty()]
					[string]$Username,

					[ValidateSet('Excel', 'HTML', 'Host')]
					[string]$Export = 'Host',

                	[ValidateScript( { if (Test-Path $_) { $true }
                                else { New-Item -Path $_ -ItemType Directory -Force | Out-Null; $true }
                    })]
                	[System.IO.DirectoryInfo]$ReportPath = 'C:\Temp',

					[ValidateScript({$IsAdmin = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
            						if ($IsAdmin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {$True}
            						else {Throw "Must be running an elevated prompt to use this function"}})]
        			[switch]$ClearARPCache,
					
        			[ValidateScript({if (Test-Connection -ComputerName $_ -Count 2 -Quiet) {$true}
                            		else {throw "Unable to connect to $($_)"} })]
        			[string[]]$ComputerName
					)



	if ($Export -eq 'Excel') { 
		$ExcelOptions = @{
            Path             = $(Join-Path -Path $ReportPath -ChildPath "\PWSHModule-$(Get-Date -Format yyyy.MM.dd-HH.mm).xlsx")
            AutoSize         = $True
            AutoFilter       = $True
            TitleBold        = $True
            TitleSize        = '28'
            TitleFillPattern = 'LightTrellis'
            TableStyle       = 'Light20'
            FreezeTopRow     = $True
            FreezePane       = '3'
        }
         $data | Export-Excel -Title PWSHModule -WorksheetName PWSHModule @ExcelOptions}

	if ($Export -eq 'HTML') { $data | Out-GridHtml -DisablePaging -Title "PWSHModule" -HideFooter -SearchHighlight -FixedHeader -FilePath $(Join-Path -Path $ReportPath -ChildPath "\PWSHModule-$(Get-Date -Format yyyy.MM.dd-HH.mm).html") }
	if ($Export -eq 'Host') { $data }
} #end Function
