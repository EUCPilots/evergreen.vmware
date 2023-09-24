# Evergreen.VMware

A PowerShell module for retrieving available product versions and downloads from the [VMware Product Downloads](https://customerconnect.vmware.com/en/downloads/#all_products) site.

## Examples

Return the available product downloads list:

```powershell
Get-VMwareProductList
```

Return the available product versions and downloads for **VMware vSphere**:

```powershell
Get-VMwareProductList -Name "VMware vSphere" | Get-VMwareProductDownload
```

Return the available product versions and downloads for the **Desktop & End-User Computing** category:

```powershell
Get-VMwareProductList | Where-Object { $_.CategoryMap -eq "desktop_end_user_computing" } | Get-VMwareProductDownload
```

Find all of the product downloads that don't require you to sign into the download site:

```powershell
Get-VMwareProductList | Get-VMwareProductDownload | Test-VMwareProductDownload | Where-Object { $_.Result -eq $true }
```

## Installing the Module

### Manual Installation from the Repository

The module can be downloaded from the [GitHub source repository](https://github.com/EUCPilots/evergreen.vmware) and includes the module in the `src` folder. The folder needs to be installed into one of your PowerShell Module Paths. To see the full list of available PowerShell Module paths, use `$env:PSModulePath.split(';')` in a PowerShell console.

Common PowerShell module paths include:

* Current User: `%USERPROFILE%\Documents\WindowsPowerShell\Modules\`
* All Users: `%ProgramFiles%\WindowsPowerShell\Modules\`
* OneDrive: `$env:OneDrive\Documents\WindowsPowerShell\Modules\`

To install from the repository

1. Download the `main branch` to your workstation
2. Copy the contents of the Evergreen folder onto your workstation into the desired PowerShell Module path
3. Open a Powershell console with the Run as Administrator option
4. Run `Set-ExecutionPolicy` using the parameter `RemoteSigned` or `Bypass`
5. Unblock the files with `Get-ChildItem -Path <path to module> -Recurse | Unblock-File`

Once installation is complete, you can validate that the module exists by running `Get-Module -ListAvailable Evergreen`. To use the module, load it with:

```powershell
Import-Module -Name ./src/Evergreen.VMware.psd1
```
