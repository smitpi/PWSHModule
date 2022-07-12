---
external help file: PWSHModule-help.xml
Module Name: PWSHModule
online version:
schema: 2.0.0
---

# Remove-PWSHModule

## SYNOPSIS
Remove a module to the config file

## SYNTAX

```
Remove-PWSHModule [-Path] <FileInfo> [[-ModuleName] <String>] [<CommonParameters>]
```

## DESCRIPTION
Remove a module to the config file

## EXAMPLES

### EXAMPLE 1
```
Remove-PWSHModule -Export HTML -ReportPath C:\temp
```

## PARAMETERS

### -Path
{{ Fill Path Description }}

```yaml
Type: FileInfo
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ModuleName
{{ Fill ModuleName Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
