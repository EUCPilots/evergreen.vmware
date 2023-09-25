---
external help file: Evergreen.VMware-help.xml
Module Name: evergreen.vmware
online version:
schema: 2.0.0
---

# Get-VMwareProductList

## SYNOPSIS
Returns a list of the available VMware products.

## SYNTAX

```
Get-VMwareProductList [[-Name] <String>] [<CommonParameters>]
```

## DESCRIPTION
Returns a list of the available VMware products and search properties for each product required by Get-VMwareProductDownload when searching for available product downloads. The Name property returned by Get-VMwareProductList is 

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-VMwareProductDownload
```

Returns all available VMware products and search properties required by Get-VMwareProductDownload.

### Example 2
```powershell
PS C:\> Get-VMwareProductList -Name "VMware vSphere"
```

Returns product name and search properties required by Get-VMwareProductDownload for VMware vSphere.

## PARAMETERS

### -Name
The name of the VMware product to return search details for.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
