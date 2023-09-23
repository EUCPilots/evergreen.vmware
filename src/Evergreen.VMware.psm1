<#
    .SYNOPSIS
        Script to initiate the module
#>
[CmdletBinding(SupportsShouldProcess = $false)]
param ()

function Get-VMwareAPIPath {
    [CmdletBinding(SupportsShouldProcess = $false)]
    [OutputType("System.String")]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet('products', 'dlg')]
        [System.String] $Endpoint = "products"
    )
    return "https://customerconnect.vmware.com/channel/public/api/v1.0/${Endpoint}"
}

function Get-VMwareRelatedDLGList {
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $CategoryMap,

        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $ProductMap,

        [Parameter(Mandatory = $true,
            Position = 2,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String] $VersionMap,

        [Parameter(Mandatory = $false)]
        [ValidateSet('PRODUCT_BINARY', 'DRIVERS_TOOLS', 'OPEN_SOURCE', 'CUSTOM_ISO', 'ADDONS')]
        [System.String] $DLGType = 'PRODUCT_BINARY'
    )

    $APIResource = 'getRelatedDLGList'
    $queryParameters = @{
        category = $CategoryMap
        product  = $ProductMap
        version  = $VersionMap
        dlgType  = $DLGType
    }
    $queryString = ( $queryParameters.GetEnumerator() | ForEach-Object { "&$($_.Key)=$($_.Value)" }) -join ''
    $params = @{
        Uri             = "$(Get-VMwareAPIPath)/$($APIResource)?$($queryString.TrimStart('&'))"
        UseBasicParsing = $true
        ErrorAction     = "Stop"
    }
    $WebResult = Invoke-WebRequest @params | ConvertFrom-Json -ErrorAction "Stop"
    Write-Output -InputObject $WebResult.dlgEditionsLists.dlgList
}

function Get-VMwareDLGHeaderQuery {
    [OutputType("System.String")]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String] $DownloadGroup,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String] $ProductId,

        [Parameter(Mandatory = $false)]
        [System.String] $Locale = 'en_US'
    )

    $APIResource = 'getDLGHeader'
    $queryParameters = @{
        locale        = $Locale
        downloadGroup = $DownloadGroup
        productId     = $ProductId
    }
    $queryString = ($queryParameters.GetEnumerator() | ForEach-Object { "&$($_.Key)=$($_.Value)" }) -join ''
    return "$(Get-VMwareAPIPath)/$($APIResource)?$($queryString.TrimStart('&'))"
}

function Get-VMwareDLGDetailsQuery {
    [OutputType("System.String")]
    param (
        [Parameter(Mandatory = $true)]
        [System.String] $DownloadGroup,
    
        [Parameter(Mandatory = $false)]
        [System.String] $Locale = 'en_US'
    )

    $APIResource = 'details'
    $queryParameters = @{
        locale        = $Locale
        downloadGroup = $DownloadGroup
    }
    $queryString = ($queryParameters.GetEnumerator() | ForEach-Object { "&$($_.Key)=$($_.Value)" }) -join ''
    return "$(Get-VMwareAPIPath -Endpoint 'dlg')/$($APIResource)?$($queryString.TrimStart('&'))"
}

function Get-VMwareProductList {
    [CmdletBinding(SupportsShouldProcess = $false)]
    param (
        [Parameter(Mandatory = $false)]
        [System.String] $Name
    )

    $APIResource = 'getProductsAtoZ'
    $params = @{
        Uri             = "$(Get-VMwareAPIPath)/${APIResource}"
        UseBasicParsing = $true
        ErrorAction     = "Stop"
    }
    $WebResult = Invoke-WebRequest @params | ConvertFrom-Json -ErrorAction "Stop"
    
    $FilteredProductList = $WebResult.productCategoryList.ProductList
    if ($PSBoundParameters.ContainsKey('Name')) {
        $FilteredProductList = $FilteredProductList | Where-Object -FilterScript { $_.Name -eq $Name }
    }

    $Result = $FilteredProductList | ForEach-Object -Process {
        $Action = $_.actions | Where-Object -FilterScript { $_.linkname -eq "Download Product" }
        [PSCustomObject]@{
            Name        = $_.Name
            CategoryMap = $($Action.target -split '/')[-3]
            ProductMap  = $($Action.target -split '/')[-2]
            VersionMap  = $($Action.target -split '/')[-1]
        }
    }
    Write-Output -InputObject $Result
}

function Get-VMwareProductDownload {
    param (
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String[]] $Name
    )

    process {
        foreach ($Product in $Name) {
            $VMwareProduct = Get-VMwareProductList -Name $Product
            $VMwareDLG = $VMwareProduct | Get-VMwareRelatedDLGList

            foreach ($Dlg in $VMwareDLG) {
                $params = @{
                    Uri         = $(Get-VMwareDLGDetailsQuery -downloadGroup $Dlg.code)
                    ErrorAction = "SilentlyContinue"
                }
                $DownloadFiles = $(Invoke-RestMethod @params).downloadFiles
                foreach ($File in $DownloadFiles) {
                    $Result = [PSCustomObject]@{
                        ProductName = $Product
                        Download    = $File.title
                        Category    = $VMwareProduct.CategoryMap
                        Version     = $File.version
                        URI         = "https://download3.vmware.com/software/$($Dlg.code)/$($File.fileName)"
                    }
                    Write-Output -InputObject $Result
                }
            }
        }
    }
}

# Export the public modules and aliases
Export-ModuleMember -Function "Get-VMwareProductList", "Get-VMwareRelatedDLGList", "Get-VMwareProductDownload" -Alias *
