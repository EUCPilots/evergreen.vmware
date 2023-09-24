<#
    .SYNOPSIS
        Script to initiate the module

    .NOTES
        Original code: https://github.com/aaronparker/evergreen/issues/474#issuecomment-1492766858
#>
[CmdletBinding(SupportsShouldProcess = $false)]
param ()

# Enable TLS 1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
$ProgressPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue

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

    process {
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
        $WebResult = Invoke-RestMethod @params
        Write-Output -InputObject $WebResult.dlgEditionsLists.dlgList
    }
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
    $WebResult = Invoke-RestMethod @params

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
                    Uri         = $(Get-VMwareDLGDetailsQuery -DownloadGroup $Dlg.code)
                    ErrorAction = "SilentlyContinue"
                }
                $DownloadFiles = $(Invoke-RestMethod @params).downloadFiles

                foreach ($File in $DownloadFiles) {
                    if ([System.String]::IsNullOrEmpty($File.title)) {
                    }
                    else {
                        $Result = [PSCustomObject]@{
                            ProductName = $Product
                            Download    = $File.title
                            Category    = $VMwareProduct.CategoryMap
                            Md5         = $File.md5checksum
                            ReleaseDate = $File.releaseDate
                            Version     = $File.version
                            URI         = "https://download3.vmware.com/software/$($Dlg.code)/$($File.fileName)"
                        }
                        Write-Output -InputObject $Result
                    }
                }
            }
        }
    }
}

function Test-VMwareProductDownload {
    <#
        .EXTERNALHELP Evergreen-help.xml
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding(SupportsShouldProcess = $true, HelpURI = "https://stealthpuppy.com/evergreen/test/", DefaultParameterSetName = "Path")]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline)]
        [ValidateNotNull()]
        [System.Management.Automation.PSObject] $InputObject,

        [Parameter(Mandatory = $false, Position = 1)]
        [System.String] $Proxy,

        [Parameter(Mandatory = $false, Position = 2)]
        [System.Management.Automation.PSCredential]
        $ProxyCredential = [System.Management.Automation.PSCredential]::Empty,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String] $UserAgent = [Microsoft.PowerShell.Commands.PSUserAgent]::Chrome,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.SwitchParameter] $Force
    )

    process {
        # Loop through each object and download to the target path
        foreach ($Object in $InputObject) {

            #region Validate the URI property and find the output filename
            if ([System.Boolean]($Object.URI)) {
            }
            else {
                throw "Object does not have valid URI property."
            }
            #endregion

            try {
                $params = @{
                    Uri             = $Object.URI
                    Method          = "HEAD"
                    UseBasicParsing = $true
                    UserAgent       = $UserAgent
                    ErrorAction     = "SilentlyContinue"
                }
                if ($PSBoundParameters.ContainsKey("Proxy")) {
                    $params.Proxy = $Proxy
                }
                if ($PSBoundParameters.ContainsKey("ProxyCredential")) {
                    $params.ProxyCredential = $ProxyCredential
                }
                $Result = $true
                Invoke-WebRequest @params | Out-Null
            }
            catch [System.Exception] {
                $Result = $false
            }

            $PSObject = [PSCustomObject] @{
                Result   = $Result
                Product  = $Object.ProductName
                Category = $Object.Category
                Version  = $Object.Version
                URI      = $Object.URI
            }
            Write-Output -InputObject $PSObject
        }
    }

    end {
        if ($PSCmdlet.ShouldProcess("Remove variables")) {
            if (Test-Path -Path Variable:params) { Remove-Variable -Name "params" -ErrorAction "SilentlyContinue" }
            Remove-Variable -Name "OutPath", "OutFile" -ErrorAction "SilentlyContinue"
        }
    }
}

<#
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
#>

# Export the public modules and aliases
Export-ModuleMember -Function "Get-VMwareProductList", "Get-VMwareProductDownload", "Test-VMwareProductDownload" -Alias *
