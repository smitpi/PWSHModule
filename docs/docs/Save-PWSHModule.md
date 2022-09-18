---
external help file: PWSHModule-help.xml
Module Name: PWSHModule
online version:
schema: 2.0.0
---

# Save-PWSHModule

## SYNOPSIS
Saves the modules from the specified list to a folder.

## SYNTAX

### Private (Default)
```
Save-PWSHModule -ListName <String[]> [-Path <DirectoryInfo>] -GitHubUserID <String> [-GitHubToken <String>]
 [<CommonParameters>]
```

### nuget
```
Save-PWSHModule -ListName <String[]> [-AsNuGet] [-Path <DirectoryInfo>] -GitHubUserID <String> [-PublicGist]
 [-GitHubToken <String>] [-LocalList] [-ListPath <DirectoryInfo>] [<CommonParameters>]
```

### modulepath
```
Save-PWSHModule -ListName <String[]> [-AddToPSModulePath] [-Path <DirectoryInfo>] -GitHubUserID <String>
 [-PublicGist] [-GitHubToken <String>] [-LocalList] [-ListPath <DirectoryInfo>] [<CommonParameters>]
```

### Public
```
Save-PWSHModule -ListName <String[]> [-Path <DirectoryInfo>] -GitHubUserID <String> [-PublicGist]
 [<CommonParameters>]
```

### local
```
Save-PWSHModule -ListName <String[]> [-Path <DirectoryInfo>] -GitHubUserID <String> [-LocalList]
 [-ListPath <DirectoryInfo>] [<CommonParameters>]
```

## DESCRIPTION
Saves the modules from the specified list to a folder.

## EXAMPLES

### EXAMPLE 1
```
Save-PWSHModule -ListName extended -AsNuGet -Path c:\temp\ -GitHubUserID smitpi -GitHubToken $GitHubToken
```

## PARAMETERS

### -ListName
The File Name on GitHub Gist.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AsNuGet
Save in the NuGet format

```yaml
Type: SwitchParameter
Parameter Sets: nuget
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -AddToPSModulePath
Add path to environmental variable PSModulePath.

```yaml
Type: SwitchParameter
Parameter Sets: modulepath
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Path
Where to save

```yaml
Type: DirectoryInfo
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: C:\Temp
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
Parameter Sets: nuget, modulepath, Public
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
Parameter Sets: Private, nuget, modulepath
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
Parameter Sets: nuget, modulepath, local
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ListPath
Directory where list files are saved.

```yaml
Type: DirectoryInfo
Parameter Sets: nuget, modulepath, local
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
