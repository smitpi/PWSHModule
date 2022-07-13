---
external help file: PWSHModule-help.xml
Module Name: PWSHModule
online version:
schema: 2.0.0
---

# Show-PWSHModuleList

## SYNOPSIS
List all the GitHub Gist Lists.

## SYNTAX

```
Show-PWSHModuleList [-GitHubUserID] <String> [-GitHubToken] <String> [<CommonParameters>]
```

## DESCRIPTION
List all the GitHub Gist Lists.

## EXAMPLES

### EXAMPLE 1
```
Show-PWSHModuleList -Export HTML -ReportPath C:\temp
```

### EXAMPLE 2
```
Show-PWSHModuleList -GitHubUserID smitpi -GitHubToken $GitHubToken
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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
