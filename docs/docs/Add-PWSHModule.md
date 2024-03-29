---
external help file: PWSHModule-help.xml
Module Name: PWSHModule
online version:
schema: 2.0.0
---

# Add-PWSHModule

## SYNOPSIS
Adds a new module to the GitHub Gist List.

## SYNTAX

```
Add-PWSHModule [-ListName] <String[]> [-ModuleName] <String[]> [[-Repository] <String>]
 [[-RequiredVersion] <String>] [-GitHubUserID] <String> [-GitHubToken] <String> [<CommonParameters>]
```

## DESCRIPTION
Adds a new module to the GitHub Gist List.

## EXAMPLES

### EXAMPLE 1
```
Add-PWSHModule -ListName base -ModuleName pslauncher -Repository PSgallery -RequiredVersion 0.1.19 -GitHubUserID smitpi -GitHubToken $GitHubToken
```

## PARAMETERS

### -ListName
The File Name on GitHub Gist.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ModuleName
Name of the module to add.
You can also use a keyword to search for.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: Name

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Repository
Name of the Repository to hosting the module.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: PSGallery
Accept pipeline input: False
Accept wildcard characters: False
```

### -RequiredVersion
This will force a version to be used.
Leave blank to use the latest version.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
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
Position: 5
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
Position: 6
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
