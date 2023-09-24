<#
    .SYNOPSIS
        Main Pester function tests.
#>
[OutputType()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification="This OK for the tests files.")]
param ()

BeforeDiscovery {
    $ModulePath = [System.IO.Path]::Combine($env:GITHUB_WORKSPACE, "src")
    $ManifestPath = [System.IO.Path]::Combine($ModulePath, "Evergreen.VMware.psd1")

    # TestCases are splatted to the script so we need hashtables
    $Scripts = Get-ChildItem -Path $ModulePath -Recurse -Include "*.ps1", "*.psm1"
    $TestCase = $Scripts | ForEach-Object { @{file = $_ } }
}

BeforeAll {
    $ModulePath = [System.IO.Path]::Combine($env:GITHUB_WORKSPACE, "src")
    $ManifestPath = [System.IO.Path]::Combine($ModulePath, "Evergreen.VMware.psd1")
}

Describe "General project validation" {
    It "Script <file.Name> should be valid PowerShell" -TestCases $TestCase {
        param ($file)
        $contents = Get-Content -Path $file.FullName -ErrorAction "Stop"
        $errors = $null
        $null = [System.Management.Automation.PSParser]::Tokenize($contents, [ref]$errors)
        $errors.Count | Should -Be 0
    }
}

# Test module and manifest
Describe "Module Metadata validation" {
    It "Script fileinfo should be OK" {
        { Test-ModuleManifest -Path $ManifestPath -ErrorAction "Stop" } | Should -Not -Throw
    }

    It "Import module should be OK" {
        { Import-Module $ManifestPath -Force -ErrorAction "Stop" } | Should -Not -Throw
    }
}

# Describe "Get-VMwareAPIPath" {
#     It "Should return products endpoint" {
#         { Get-VMwareAPIPath -Endpoint "products"} | Should -Equal "https://customerconnect.vmware.com/channel/public/api/v1.0/products"
#     }

#     It "Should return dlg endpoint" {
#         { Get-VMwareAPIPath -Endpoint "dlg"} | Should -Equal "https://customerconnect.vmware.com/channel/public/api/v1.0/products"
#     }
# }

Describe "Get-VMwareProductList" {
    BeforeAll {
        $Product = Get-VMwareProductList -Name "VMware vSphere"
    }

    It "Should have a Name property" {
        $Product.Name | Should -Not -BeNullOrEmpty
    }

    It "Should have a CategoryMap property" {
        $Product.CategoryMap | Should -Not -BeNullOrEmpty
    }

    It "Should have a ProductMap property" {
        $Product.ProductMap | Should -Not -BeNullOrEmpty
    }

    It "Should have a VersionMap property" {
        $Product.VersionMap | Should -Not -BeNullOrEmpty
    }
}

Describe "Get-VMwareProductDownload" {
    BeforeDiscovery {
        $Download = Get-VMwareProductList -Name "VMware vSphere" | Get-VMwareProductDownload
    }

    Context "Test Get-VMwareProductDownload output" -ForEach $Download {
        BeforeAll {
            $Item = $_
        }

        It "Should have a ProductName property" {
            $Item.ProductName | Should -Not -BeNullOrEmpty
        }

        It "Should have a Download property" {
            $Item.Download | Should -Not -BeNullOrEmpty
        }

        It "Should have a Category property" {
            $Item.Category | Should -Not -BeNullOrEmpty
        }

        It "Should have a Md5 property" {
            $Item.Md5 | Should -Not -BeNullOrEmpty
        }

        It "Should have a ReleaseDate property" {
            $Item.ReleaseDate | Should -Not -BeNullOrEmpty
        }

        It "Should have a Version property" {
            $Item.Version | Should -Not -BeNullOrEmpty
        }

        It "Should have a URI property" {
            $Item.URI | Should -Not -BeNullOrEmpty
        }
    }
}
