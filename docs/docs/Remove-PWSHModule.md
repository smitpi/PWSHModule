---
external help file: PWSHModule-help.xml
Module Name: PWSHModule
online version:
schema: 2.0.0
---

# Remove-PWSHModule

## SYNOPSIS
Remove module from the specified list.

## SYNTAX

```
Remove-PWSHModule [-GitHubUserID] <String> [-GitHubToken] <String> [-ListName] <String>
 [-ModuleName] <String[]> [<CommonParameters>]
```

## DESCRIPTION
Remove module from the specified list.

## EXAMPLES

### EXAMPLE 1
```
Remove-PWSHModule -GitHubUserID smitpi -GitHubToken $GitHubToken -ListName base -ModuleName pslauncher
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

### -ModuleName
Module to remove

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: Name

Required: True
Position: 4
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
