---
external help file: PWSHModule-help.xml
Module Name: PWSHModule
online version:
schema: 2.0.0
---

# Move-PWSHModuleBetweenScope

## SYNOPSIS
Moves modules between scopes (CurrentUser and AllUsers).

## SYNTAX

```
Move-PWSHModuleBetweenScope [-SourceScope] <DirectoryInfo> [-DestinationScope] <DirectoryInfo>
 [[-ModuleName] <String[]>] [[-Repository] <String>] [<CommonParameters>]
```

## DESCRIPTION
Moves modules between scopes (CurrentUser and AllUsers).

## EXAMPLES

### EXAMPLE 1
```
Move-PWSHModuleBetweenScope -SourceScope D:\Documents\PowerShell\Modules -DestinationScope C:\Program Files\PowerShell\Modules -ModuleName PWSHMOdule -Repository psgallery
```

## PARAMETERS

### -SourceScope
From where the modules will be copied.

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
To there the modules will be copied.

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
Name of the modules to move.
You can select multiple names or you can use * to select all.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: Name

Required: False
Position: 3
Default value: All
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Repository
The repository will be used to install the module at the destination.

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
