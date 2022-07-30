---
external help file: PWSHModule-help.xml
Module Name: PWSHModule
online version:
schema: 2.0.0
---

# New-PWSHModuleList

## SYNOPSIS
Add a new list to GitHub Gist.

## SYNTAX

```
New-PWSHModuleList [-GitHubUserID] <String> [-GitHubToken] <String> [-ListName] <String>
 [-Description] <String> [-AddDefaultsToProfile] [<CommonParameters>]
```

## DESCRIPTION
Add a new list to GitHub Gist.

## EXAMPLES

### EXAMPLE 1
```
New-PWSHModuleList -GitHubUserID smitpi -GitHubToken $GitHubToken -ListName Base -Description "These modules needs to be installed on all servers"
```

## PARAMETERS

### -GitHubUserID
The GitHub User ID.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -GitHubToken
GitHub Token with access to the Users' Gist.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
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
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description
Summary of the function for the list.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AddDefaultsToProfile
This will add the userid and token to $PSDefaultParameterValues and save it in your profile file.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
