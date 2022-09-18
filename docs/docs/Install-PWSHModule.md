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
Install-PWSHModule [[-ListName] <String[]>] [[-Scope] <String>] [-AllowPrerelease] -GitHubUserID <String>
 [-GitHubToken <String>] [-Repository <String>] [<CommonParameters>]
```

### Public
```
Install-PWSHModule [[-ListName] <String[]>] [[-Scope] <String>] [-AllowPrerelease] -GitHubUserID <String>
 [-PublicGist] [-Repository <String>] [<CommonParameters>]
```

### local
```
Install-PWSHModule [[-ListName] <String[]>] [[-Scope] <String>] [-AllowPrerelease] [-LocalList]
 [-Path <DirectoryInfo>] [-Repository <String>] [<CommonParameters>]
```

## DESCRIPTION
Install modules from the specified list.

## EXAMPLES

### EXAMPLE 1
```
Install-PWSHModule -Filename extended -Scope CurrentUser -GitHubUserID smitpi -GitHubToken $GitHubToken
```

## PARAMETERS

### -ListName
The File Name on GitHub Gist.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
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
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AllowPrerelease
Allow the installation on beta modules.

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
Parameter Sets: Private, Public
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

### -LocalList
Select if the list is saved locally.

```yaml
Type: SwitchParameter
Parameter Sets: local
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Path
Directory where files are saved.

```yaml
Type: DirectoryInfo
Parameter Sets: local
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Repository
Override the repository listed in the config file.

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

## NOTES

## RELATED LINKS
