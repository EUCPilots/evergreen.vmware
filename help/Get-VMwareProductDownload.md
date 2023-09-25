---
external help file: Evergreen.VMware-help.xml
Module Name: evergreen.vmware
online version:
schema: 2.0.0
---

# Get-VMwareProductDownload

## SYNOPSIS
Returns an array of available product downloads from the VMware Product Downloads site.

## SYNTAX

```
Get-VMwareProductDownload [-Name] <String[]> [<CommonParameters>]
```

## DESCRIPTION
Returns an array of all available product downloads or downloads for a specific product from the VMware Product Downloads site. Properties returned include the product name, release date, version number and download URL.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-VMwareProductList
```

Returns all available product downloads.

### Example 2
```powershell
PS C:\> Get-VMwareProductList -Name "VMware vSphere" | Get-VMwareProductDownload
```

Return the available product versions and downloads for VMware vSphere.

### Example 3
```powershell
Get-VMwareProductList | Where-Object { $_.CategoryMap -eq "desktop_end_user_computing" } | Get-VMwareProductDownload
```

Return the available product versions and downloads for the Desktop & End-User Computing category.

### Example 4
```powershell
Get-VMwareProductList | Get-VMwareProductDownload | Test-VMwareProductDownload | Where-Object { $_.Result -eq $true }
```

Find all of the product downloads that don't require you to sign into the download site.

## PARAMETERS

### -Name
The VMware product name to return download details for.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String[]
## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
