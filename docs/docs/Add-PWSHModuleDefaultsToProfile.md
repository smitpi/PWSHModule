---
external help file: PWSHModule-help.xml
Module Name: PWSHModule
online version:
schema: 2.0.0
---

# Add-PWSHModuleDefaultsToProfile

## SYNOPSIS
Creates PSDefaultParameterValues in the users profile files.

## SYNTAX

### Public (Default)
```
Add-PWSHModuleDefaultsToProfile -GitHubUserID <String> [-PublicGist] [-Scope <String>] [<CommonParameters>]
```

### Private
```
Add-PWSHModuleDefaultsToProfile -GitHubUserID <String> [-GitHubToken <String>] [-Scope <String>]
 [<CommonParameters>]
```

## DESCRIPTION
Creates PSDefaultParameterValues in the users profile files.

## EXAMPLES

### EXAMPLE 1
```
Add-PWSHModuleDefaultsToProfile -GitHubUserID smitpi -PublicGist -Scope AllUsers
```

## PARAMETERS

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

### -Scope
Where the module will be installed.
AllUsers require admin access.

```yaml
Type: String
Parameter Sets: (All)
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

### System.Object[]
## NOTES

## RELATED LINKS
