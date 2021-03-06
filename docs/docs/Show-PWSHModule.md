---
external help file: PWSHModule-help.xml
Module Name: PWSHModule
online version:
schema: 2.0.0
---

# Show-PWSHModule

## SYNOPSIS
Show the details of the modules in a list.

## SYNTAX

### Private (Default)
```
Show-PWSHModule -GitHubUserID <String> [-GitHubToken <String>] -ListName <String> [-CompareInstalled]
 [-ShowProjectURI] [<CommonParameters>]
```

### Public
```
Show-PWSHModule -GitHubUserID <String> [-PublicGist] -ListName <String> [-CompareInstalled] [-ShowProjectURI]
 [<CommonParameters>]
```

## DESCRIPTION
Show the details of the modules in a list.

## EXAMPLES

### EXAMPLE 1
```
Show-PWSHModule -GitHubUserID smitpi -GitHubToken $GitHubToken -ListName Base
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

### -CompareInstalled
Compare the list to what is installed.

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

### -ShowProjectURI
Will open the browser to the the project URL.

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
