---
external help file: PWSHModule-help.xml
Module Name: PWSHModule
online version:
schema: 2.0.0
---

# Uninstall-PWSHModule

## SYNOPSIS
Will uninstall the module from the system.

## SYNTAX

### Private (Default)
```
Uninstall-PWSHModule -ListName <String> -ModuleName <String[]> [-OldVersions] [-ForceDeleteFolder]
 -GitHubUserID <String> [-GitHubToken <String>] [<CommonParameters>]
```

### Public
```
Uninstall-PWSHModule -ListName <String> -ModuleName <String[]> [-OldVersions] [-ForceDeleteFolder]
 -GitHubUserID <String> [-PublicGist] [<CommonParameters>]
```

## DESCRIPTION
Will uninstall the module from the system.
Select OldVersions to remove duplicates only.

## EXAMPLES

### EXAMPLE 1
```
Uninstall-PWSHModule  -ListName base -OldVersions -GitHubUserID smitpi -PublicGist
```

## PARAMETERS

### -ListName
The File Name on GitHub Gist.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ModuleName
Name of the module to uninstall.
Use * to select all modules in the list.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: Name

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -OldVersions
Will only uninstall old versions of the module.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ForceDeleteFolder
Will force delete the base folder.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -GitHubUserID
The GitHub User ID.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PublicGist
Select if the list is hosted publicly.

```yaml
Type: SwitchParameter
Parameter Sets: Public
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -GitHubToken
GitHub Token with access to the Users' Gist.

```yaml
Type: String
Parameter Sets: Private
Aliases:

Required: False
Position: Named
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
