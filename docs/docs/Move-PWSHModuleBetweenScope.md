---
external help file: PWSHModule-help.xml
Module Name: PWSHModule
online version:
schema: 2.0.0
---

# Move-PWSHModuleBetweenScope

## SYNOPSIS
Will move modules between scopes (CurrentUser and AllUsers)

## SYNTAX

```
Move-PWSHModuleBetweenScope [-SourceScope] <DirectoryInfo> [-DestinationScope] <DirectoryInfo>
 [-ModuleName] <String[]> [[-PSRepository] <String>] [<CommonParameters>]
```

## DESCRIPTION
Will move modules between scopes (CurrentUser and AllUsers)

## EXAMPLES

### EXAMPLE 1
```
Move-PWSHModuleBetweenScope -Export HTML -ReportPath C:\temp
```

## PARAMETERS

### -SourceScope
{{ Fill SourceScope Description }}

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

### -DestinationScope
{{ Fill DestinationScope Description }}

```yaml
Type: DirectoryInfo
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ModuleName
{{ Fill ModuleName Description }}

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: Name

Required: True
Position: 3
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -PSRepository
{{ Fill PSRepository Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: PSGallery
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
