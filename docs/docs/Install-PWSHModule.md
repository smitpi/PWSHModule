---
external help file: PWSHModule-help.xml
Module Name: PWSHModule
online version:
schema: 2.0.0
---

# Install-PWSHModule

## SYNOPSIS
Install modules from the specified list.

## SYNTAX

### Private (Default)
```
Install-PWSHModule -GitHubUserID <String> [-GitHubToken <String>] -ListName <String> -Scope <String>
 [<CommonParameters>]
```

### Public
```
Install-PWSHModule -GitHubUserID <String> [-PublicGist] -ListName <String> -Scope <String> [<CommonParameters>]
```

## DESCRIPTION
Install modules from the specified list.

## EXAMPLES

### EXAMPLE 1
```
Install-PWSHModule -GitHubUserID smitpi -GitHubToken $GitHubToken -Filename extended -Scope CurrentUser
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

### -Scope
Where the module will be installed.
AllUsers require admin access.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
