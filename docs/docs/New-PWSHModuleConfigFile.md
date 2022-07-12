---
external help file: PWSHModule-help.xml
Module Name: PWSHModule
online version:
schema: 2.0.0
---

# New-PWSHModuleConfigFile

## SYNOPSIS
Create a new config file.

## SYNTAX

```
New-PWSHModuleConfigFile [-Path] <DirectoryInfo> [[-Description] <String>] [<CommonParameters>]
```

## DESCRIPTION
Create a new json config file in the path specified.

## EXAMPLES

### EXAMPLE 1
```
New-PWSHModuleConfigFile -Export HTML -ReportPath C:\temp
```

### EXAMPLE 2
```
New-PWSHModuleConfigFile -Path C:\temp
```

## PARAMETERS

### -Path
Path where the config file will be created.
If the path doesn't exist, it will be created.

```yaml
Type: DirectoryInfo
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description
{{ Fill Description Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: Created by PWSHModule PowerShell Module.
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Object[]
## NOTES

## RELATED LINKS
