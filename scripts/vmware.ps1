function Get-VMWareAPIPath {
    [CmdletBinding()]
    [OutputType("System.String")]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet('products', 'dlg')]
        [System.String]$endpoint = "products"
    )
    return "https://customerconnect.vmware.com/channel/public/api/v1.0/${endpoint}"
}

function Get-VMWareProductList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [System.String]$Name
    )
    $APIResource = 'getProductsAtoZ'
    $URL = "$((Get-VMWareAPIPath).TrimEnd('/'))/${APIResource}"
    $WebResult = Invoke-WebRequest -Uri $URL | ConvertFrom-Json
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

function Get-VMWareRelatedDLGList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][System.String] $CategoryMap,
        [Parameter(Mandatory = $true)][System.String] $ProductMap,
        [Parameter(Mandatory = $true)][System.String] $VersionMap,
        [Parameter(Mandatory = $false)]
        [ValidateSet('PRODUCT_BINARY', 'DRIVERS_TOOLS', 'OPEN_SOURCE', 'CUSTOM_ISO', 'ADDONS')]
        [System.String] $DLGType = 'PRODUCT_BINARY'
    )
    $APIResource = 'getRelatedDLGList'
    $APIPath = (Get-VMWareAPIPath).TrimEnd('/')
    $queryParameters = @{
        category = $CategoryMap
        product  = $ProductMap
        version  = $VersionMap
        dlgType  = $DLGType
    }
    $queryString = ( $queryParameters.GetEnumerator() | ForEach-Object { "&$($_.Key)=$($_.Value)" }) -join ''
    $URL = "$($APIPath)/$($APIResource)?$($queryString.TrimStart('&'))"
    $WebResult = Invoke-WebRequest -Uri $URL | ConvertFrom-Json
    $Result = $WebResult.dlgEditionsLists.dlgList
    if ($Result.Count -gt 1) {
        # $Result = $Result | Where-Object -FilterScript { $_.name -like "*for Windows" }
        # $Result = $Result | Where-Object -FilterScript { $_.name -like "*for Linux" }
    }
    return $Result
}

function Get-VMWareDLGHeaderQuery {
    param (
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][System.String] $downloadGroup,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][System.String] $ProductId,
        [Parameter(Mandatory = $false)]
        [System.String] $locale = 'en_US'
    )
    $APIResource = 'getDLGHeader'
    $APIPath = (Get-VMWareAPIPath).TrimEnd('/')
    $queryParameters = @{
        locale        = $Locale
        downloadGroup = $DownloadGroup
        productId     = $ProductId
    }
    $queryString = ($queryParameters.GetEnumerator() | ForEach-Object { "&$($_.Key)=$($_.Value)" }) -join ''
    return "$($APIPath)/$($APIResource)?$($queryString.TrimStart('&'))"
}

function Get-VMWareDLGDetailsQuery {
    param (
        [Parameter(Mandatory = $true)][System.String] $downloadGroup,
        [Parameter(Mandatory = $false)]
        [System.String] $locale = 'en_US'
    )
    $APIResource = 'details'
    $APIPath = (Get-VMWareAPIPath -endpoint 'dlg').TrimEnd('/')
    $queryParameters = @{
        locale        = $Locale
        downloadGroup = $DownloadGroup
    }
    $queryString = ($queryParameters.GetEnumerator() | ForEach-Object { "&$($_.Key)=$($_.Value)" }) -join ''
    return "$($APIPath)/$($APIResource)?$($queryString.TrimStart('&'))"
}

function Get-VMWareGetUpdate {
    param (
        [Parameter(Mandatory = $true)]
        #[ValidateSet('VMware Workstation Player', 'VMware Workstation Pro')]
        [System.String] $ProductName
    )

    Write-Host $ProductName -ForegroundColor Cyan
    $VMWareProduct = Get-VMWareProductList -Name $ProductName
    $VMWareDLG = Get-VMWareRelatedDLGList -CategoryMap $VMWareProduct.CategoryMap -ProductMap $VMWareProduct.ProductMap -VersionMap $VMWareProduct.VersionMap

    foreach ($Dlg in $VMwareDLG) {
        $params = @{
            Uri         = $(Get-VMWareDLGDetailsQuery -downloadGroup $Dlg.code)
            ErrorAction = "SilentlyContinue"
        }
        $DownloadFiles = $(Invoke-RestMethod @params).downloadFiles
        foreach ($File in $DownloadFiles) {
            $Result = [PSCustomObject]@{
                ProductName = $File.title
                Version     = $File.version
                URI         = "https://download3.vmware.com/software/$($VMWareDLG.code)/$($File.fileName)"
            }
            Write-Output $Result
        }
    }
}
